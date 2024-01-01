var File = require('qbs.File')
var FileInfo = require('qbs.FileInfo')

function listFiles(dir, recurse) {
	recurse = recurse || false

	var files = File.directoryEntries(dir, File.Files).map(function (file) {
		return FileInfo.joinPaths(dir, file);
	});

	if (recurse) {
		files = files.concat(
			File.directoryEntries(dir, File.Dirs | File.NoDotAndDotDot).reduce(function (acc, innerDir) {
				return acc.concat(listFiles(FileInfo.joinPaths(dir, innerDir), recurse))
			}, [])
		)
	}

	return files;
}

function compiledFiles(filePath) {
	try {
		var f = new TextFile(filePath)
		return f.readAll().split('\n')
	} finally {
		if (f) f.close()
	}
}

function processPdcOutput(filePath, basePath) {
	try {
		var f = new TextFile(filePath)
		return f.readAll()
			.split('\n')
			.map(function (line) {
				var matchedString = /^(Compiling|Copying) (.+)$/.exec(line)
				if (!matchedString)
					return ''

				var matchedAction = matchedString[1].toLowerCase() + ' '
				var matchedPath = matchedString[2]
				if (FileInfo.isAbsolutePath(matchedPath)) {
					if (basePath !== undefined) {
						if (matchedPath.startsWith(basePath)) {
							return matchedAction + FileInfo.relativePath(basePath, matchedPath)
						} else {
							return ''
						}
					} else {
						return matchedAction + FileInfo.fileName(matchedPath)
					}
				} else {
					return matchedAction + matchedPath
				}
			})
			.filter(function (line) {
				return line.length !== 0
			})
	} finally {
		if (f) f.close()
	}
}
