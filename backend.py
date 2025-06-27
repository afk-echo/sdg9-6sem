from fastapi import FastAPI
from pydantic import BaseModel
import subprocess
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor
import googletrans
translator = googletrans.Translator()

async def translate_text(text: str, src: str, dest: str) -> str:
    result = await translator.translate(text, src=src, dest=dest)
    return result.text

app = FastAPI()

# --- Load your dataset once at startup ---
df = pd.read_csv('Commodity Dataset2.csv')

# --- Random Forest functions for price forecasting ---
def train_rf(district, commodity, variety):
    filtered_df = df[
        (df['District'] == district) &
        (df['Commodity'] == commodity) &
        (df['Variety'] == variety)
    ].copy()
    if filtered_df.empty:
        return None
    filtered_df['Arrival_Date'] = pd.to_datetime(filtered_df['Arrival_Date'], dayfirst=True, format='%d-%m-%Y')
    filtered_df = filtered_df.sort_values('Arrival_Date')
    filtered_df['Date_Ordinal'] = filtered_df['Arrival_Date'].map(pd.Timestamp.toordinal)
    filtered_df['Month'] = filtered_df['Arrival_Date'].dt.month
    filtered_df['Year'] = filtered_df['Arrival_Date'].dt.year
    filtered_df['DayOfWeek'] = filtered_df['Arrival_Date'].dt.dayofweek
    X = filtered_df[['Date_Ordinal', 'Month', 'Year', 'DayOfWeek']]
    y = filtered_df['Modal_Price'].values
    rf = RandomForestRegressor(n_estimators=100, random_state=42)
    rf.fit(X, y)
    return rf, filtered_df

def forecast_price(district, commodity, variety, forecast_date):
    rf_data = train_rf(district, commodity, variety)
    if rf_data is None:
        return -1
    rf, filtered_df = rf_data
    future_date = pd.to_datetime(forecast_date)
    future_features = np.array([
        [future_date.toordinal(), future_date.month, future_date.year, future_date.dayofweek]
    ])
    try:
        pred_price = rf.predict(future_features)[0]
        return float(pred_price)
    except Exception:
        return -1

# --- Schemas ---
class CropRotationRequest(BaseModel):
    user_paragraph: str

class PriceForecastRequest(BaseModel):
    district: str
    commodity: str
    variety: str
    forecast_date: str

# --- Endpoints ---

@app.post("/crop-rotation")
async def crop_rotation(request: CropRotationRequest):
    english_input = await translate_text(request.user_paragraph, src="kn", dest="en")
    print(english_input)
    ollama_cmd = [
        "ollama", "run", "crop-forecast"
    ]
    process = subprocess.Popen(
        ollama_cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    llm_output, llm_err = process.communicate(input=english_input)
    kannada_output = await translate_text(llm_output.strip(), src="en", dest="kn")
    return {"crop_rotation_advice": kannada_output.strip()}

@app.post("/price-forecast", response_model=float)
async def price_forecast(request: PriceForecastRequest):
    price = forecast_price(request.district, request.commodity, request.variety, request.forecast_date)
    return price
