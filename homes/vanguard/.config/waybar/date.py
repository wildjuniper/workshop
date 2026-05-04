from datetime import datetime

now = datetime.now()
print(f"{now:%m/%d/%Y} ({now:%A})".lower())
