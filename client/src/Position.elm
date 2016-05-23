module Position where


type Position a = Visible (Float, Float) | Hidden (Float, Float)


type PositionOnline = Prediction (Position (Float, Float)) | Actual (Position (Float, Float))