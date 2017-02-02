all: check_cloudtrail.zip

check_cloudtrail.zip: lambda-check-cloudtrail/check_cloudtrail.py
		zip -j check_cloudtrail.zip lambda-check-cloudtrail/check_cloudtrail.py

clean:
		rm -f check_cloudtrail.zip
