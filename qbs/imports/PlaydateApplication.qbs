import qbs.FileInfo

Application {
	Depends { name: 'bundle' }
	Depends { name: 'Playdate.sdk' }
	Depends { name: 'Playdate.pdxinfo' }

	type: ['playdate.bundle.content', 'playdate.bundle.pdxinfo']

	bundle.isBundle: false

	PlaydateBundle {
		qbs.install: true
		qbs.installSourceBase: product.buildDirectory
	}
}
