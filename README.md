#LocationService

**LocationService** is a simple, drop-in location manager for iOS written in Swift 4. 

It does two things:

1. Handles authorization  
2. Fetches the name of a user's current location  

It is written so whichever object holds reference to the service (a `ViewController`, `ViewModel,` etc) does not have to import `CoreLocation` or its delegate methods.

It can be expanded upon and improved -- please feel free to submit a pull request if you have changes that make it better!

##Notes

####Authorization  
For authorization, it only accepts `When In Use` as being properly authorized.  
You can customize this yourself in the `CLLocationManagerDelegate` method.

####Location Name  
The service defaults to fetching the `sublocality` and `administrativeArea` as its first priority. It then goes futher up the location hierarchy, until `country`. If it can't fetch any of the above, it errors out.  
These priorities can be changed in `LocationService`'s `reverseGeocode(...)` method.

##Example Usage
```swift
final class ViewController: UIViewController {

	let locationService = LocationService()

	var locationName: String? 

// ... 

	func requestLocationName() {

		locationService.requestLocationName({ locationName, error in
			if let name = locationName {
				self.locationName = name
			} else if let error = error {
				// Handle error here
			}
		})
	}

}

```