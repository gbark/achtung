module Position where




type Position a = Visible (Float, Float) | Hidden (Float, Float)


type PositionOnline a = Fake (Position a) | Real (Position a)