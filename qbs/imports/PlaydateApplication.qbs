import qbs.FileInfo

Application {
	Depends { name: 'bundle' }
	Depends { name: 'playdate' }

	type: ['playdate.bundle.content', 'playdate.bundle.pdxinfo']

	bundle.isBundle: false

	PlaydateBundle {
		qbs.install: true
		qbs.installSourceBase: playdate.buildDirectory
	}
}
