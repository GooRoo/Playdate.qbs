import qbs.FileInfo

Application {
	Depends { name: 'bundle' }
	Depends { name: 'Playdate.sdk' }
	Depends { name: 'Playdate.metadata' }

	type: ['playdate.bundle.content', 'playdate.bundle.pdxinfo']

	bundle.isBundle: false

	Group {
		name: 'Source'
		prefix: product.Playdate.sdk.sourceDir + '/'
		files: ['**']
	}

	PlaydateBundle {
		qbs.install: true
		qbs.installSourceBase: product.buildDirectory
	}
}
