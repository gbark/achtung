module Position where




type Position a = Visible (Float, Float) | Hidden (Float, Float)


type PositionOnline = Fake (Position (Float, Float)) | Real (Position (Float, Float))