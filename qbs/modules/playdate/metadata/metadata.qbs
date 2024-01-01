Module {
	property string bundleName: product.name
	PropertyOptions {
		name: 'bundleName'
		description: 'A name of your application.'
	}

	property string author
	PropertyOptions {
		name: 'author'
		description: 'An author of your application.'
	}

	property string description
	PropertyOptions {
		name: 'description'
		description: 'A description of your application.'
	}

	property string bundleId
	PropertyOptions {
		name: 'bundleId'
		description: 'A unique identifier for your application, in reverse DNS notation.'
	}

	property string version: product.version
	PropertyOptions {
		name: 'version'
		description:
			'An application version number, formatted any way you wish, that is displayed to players. ' +
			'It is not used to compute when updates should occur.'
	}

	property int buildNumber: -1
	PropertyOptions {
		name: 'buildNumber'
		description:
			'A monotonically-increasing integer value used to indicate a unique version of your application. ' +
			'This can be set using an automated build process like Continuous Integration to avoid having ' +
			'to set the value by hand.'
	}

	property path imagePath
	PropertyOptions {
		name: 'imagePath'
		description:
			'A directory of images that will be used by the launcher. ' +
			'The path is relative to `Playdate.sdk.sourceDirectory`.'
	}

	property path launchSoundPath
	PropertyOptions {
		name: 'launchSoundPath'
		description:
			'(Optional.) Should point to the path of a short audio file to be played as the application launch ' +
			'animation is taking place. The path is relative to `Playdate.sdk.sourceDirectory`.'
	}

	property string contentWarning
	PropertyOptions {
		name: 'contentWarning'
		description:
			'(Optional.) A content warning that displays when the user launches your application for the first ' +
			'time. The user will have the option of backing out and not launching your application if they choose.'
	}

	property string contentWarning2
	PropertyOptions {
		name: 'contentWarning2'
		description:
			'(Optional.) A second content warning that displays on a second screen when the user launches ' +
			'your application for the first time. The user will have the option of backing out and not launching ' +
			'your application if they choose. Note: `contentWarning2` will only display if a `contentWarning` ' +
			'attribute is also specified.'
	}

}
