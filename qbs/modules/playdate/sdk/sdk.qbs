import qbs.File
import qbs.FileInfo
import qbs.Probes
import qbs.Process
import qbs.TextFile

import 'pd.js' as PD
import 'polyfill.js' as $

Module {
	property pathList paths: []
	property path pdcPath: pdcProbe.filePath
	property string targetName: product.targetName + '.pdx'
	readonly property path targetDir: FileInfo.joinPaths(product.buildDirectory, targetName)
	property string sourceDirectory: 'source'
	readonly property path sourceDir: FileInfo.joinPaths(product.sourceDirectory, sourceDirectory)

	additionalProductTypes: ['playdate.bundle.content', 'playdate.bundle.pdxinfo']

	Probes.BinaryProbe {
		id: pdcProbe
		names: 'pdc'
		searchPaths: product.Playdate.sdk.paths
		environmentPaths: ['PLAYDATE_SDK_PATH']
	}

	validate: {
		if (!File.exists(pdcPath)) {
			throw 'The executalbe ' + pdcPath + ' does not exist. Please, make sure Playdate SDK is installed.'
		}
	}

	FileTagger {
		fileTags: ['playdate.lua']
		patterns: [
			'*.lua',
		]
	}

	FileTagger {
		fileTags: ['playdate.imagetable']
		patterns: [
			'*-table-*-*.jpeg',
			'*-table-*-*.jpg',
			'*-table-*-*.png',
			'*-table-*-*.tif',
			'*-table-*-*.tiff',
		]
		priority: 1
	}

	FileTagger {
		fileTags: ['playdate.image']
		patterns: [
			'*.jpeg',
			'*.jpg',
			'*.png',
			'*.tif',
			'*.tiff',
			'*.webm',
		]
	}

	FileTagger {
		fileTags: ['playdate.audio']
		patterns: [
			'*.aif',
			'*.aiff',
			'*.mp3',
			'*.wav',
		]
	}

	FileTagger {
		fileTags: ['playdate.font']
		patterns: [
			'*.fnt',
		]
	}

	FileTagger {
		fileTags: ['playdate.pdxinfo']
		patterns: 'pdxinfo'
	}

	Rule {
		multiplex: true
		inputs: [
			'playdate.audio',
			'playdate.font',
			'playdate.image',
			'playdate.imagetable',
			'playdate.lua',
			'playdate.pdxinfo',
			'playdate.strings',
			'playdate.video',
		]

		Artifact {
			filePath: 'pdc.output'
			fileTags: ['playdate.pdc-output']
		}
		Artifact {
			filePath: 'pdc.result'
			fileTags: ['playdate.pdc-result']
		}
		Artifact {
			filePath: 'pdc.pdxinfo'
			fileTags: ['playdate.pdxinfo-gen']
		}

		prepare: /* (project, product, inputs, outputs, input, output, explicitlyDependsOn) => */ {
			var cmds = []

			for (var k in inputs) {
				for (var l in inputs[k]) {
					console.debug('[playdate] Tagged [' + k + '].' + l + ': ' + inputs[k][l].fileName)
				}
			}

			var pdcPath = product.Playdate.sdk.pdcPath

			var pdc = new Command(pdcPath, [
				'--verbose',
				product.Playdate.sdk.sourceDir,
				product.Playdate.sdk.targetDir,
			])
			pdc.silent = true
			pdc.highlight = 'compiler'
			pdc.relevantEnvironmentVariables = ['PLAYDATE_SDK_PATH', 'PLAYDATE_LIB_PATH']
			pdc.stdoutFilePath = outputs['playdate.pdc-output'][0].filePath
			cmds.push(pdc)

			var movePdxInfo = new JavaScriptCommand()
			movePdxInfo.silent = true
			movePdxInfo.sourceCode = function () {
				File.move(
					FileInfo.joinPaths(product.Playdate.sdk.targetDir, 'pdxinfo'),
					FileInfo.joinPaths(product.Playdate.sdk.targetDir, '..', 'pdc.pdxinfo')
				)
			}
			cmds.push(movePdxInfo)

			var listResults = new JavaScriptCommand()
			listResults.silent = true
			listResults.sourceCode = function () {
				var files = PD.listFiles(product.Playdate.sdk.targetDir, true)
				if (files.length > 0) {
					var compilationResults = new TextFile(outputs['playdate.pdc-result'][0].filePath, TextFile.WriteOnly)
					compilationResults.write(files.join('\n'))
					compilationResults.close()
				}
			}
			cmds.push(listResults)

			return cmds
		}
	}

	Scanner {
		inputs: ['playdate.pdc-result', 'playdate.pdc-output']
		scan: /* (project, product, input, filePath) => */ PD.compiledFiles(filePath)
	}

	Rule {
		multiplex: true
		requiresInputs: false

		inputs: ['playdate.pdxinfo-gen']

		Artifact {
			filePath: FileInfo.joinPaths(product.Playdate.sdk.targetDir, 'pdxinfo')
			fileTags: ['playdate.bundle.pdxinfo']
		}

		prepare: /* (project, product, inputs, outputs, input, output, explicitlyDependsOn) => */ {
			var cmd = new JavaScriptCommand()
			cmd.description = 'generating pdxinfo'
			cmd.highlight = 'codegen'
			cmd.sourceCode = function () {
				function maybeUpdate(dict, invalid, key, value) {
					if (!invalid(value)) {
						dict[key] = value
					}
				}

				var pdx = product.Playdate.metadata

				var inFile = new TextFile(input.filePath)
				var props = inFile.readAll().split('\n').reduce(function (acc, line) {
					if (line.length !== 0) {
						var prop = line.split('=')
						var propKey = prop[0], propValue = prop[1]
						console.debug('[playdate.pdxinfo] Read ' + propKey + ' = ' + propValue)
						acc[propKey] = propValue
					}
					return acc
				}, {})
				inFile.close()

				var updateString = $.partial(maybeUpdate, props, $.isUndefined)
				var updateInt = $.partial(maybeUpdate, props, $.isMinusOne)
				var updatePath = function (key, path) {
					var relPath = !path || path === ''? undefined : FileInfo.relativePath(product.Playdate.sdk.sourceDir, path)
					maybeUpdate(props, $.isUndefined, key, relPath)
				}

				updateString('name', pdx.bundleName)
				updateString('author', pdx.author)
				updateString('description', pdx.description)
				updateString('bundleID', pdx.bundleId)
				updateString('version', pdx.version)
				updateInt('buildNumber', pdx.buildNumber)
				updatePath('imagePath', pdx.absoluteImagePath)
				updatePath('launchSoundPath', pdx.absoluteLaunchSoundPath)
				updateString('contentWarning', pdx.contentWarning)
				updateString('contentWarning2', pdx.contentWarning2)

				var outFile = new TextFile(output.filePath, TextFile.WriteOnly)
				for (var propKey in props) {
					outFile.writeLine(propKey + '=' + props[propKey])
				}
				outFile.close()
			}

			return [cmd]
		}
	}

	Rule {
		multiplex: true
		inputs: ['playdate.pdc-result', 'playdate.pdc-output']

		outputArtifacts: {
			function filenameToTags(f) {
				var tags = ['playdate.bundle.content']
				var knownExtensions = ['pda', 'pdi', 'pds', 'pdt', 'pdv', 'pdz', 'pft']
				var suffix = FileInfo.suffix(f)
				if (knownExtensions.contains(suffix))
					tags.push('playdate.' + suffix)
				return tags
			}

			return PD.compiledFiles(inputs['playdate.pdc-result'][0].filePath)
				.filter(function (line) {
					return FileInfo.fileName(line) !== 'pdxinfo'
				})
				.map(function (file) {
					return {
						filePath: file,
						fileTags: filenameToTags(file)
					}
				})
		}

		outputFileTags: [
			'playdate.bundle.content',
			'playdate.pda',
			'playdate.pdi',
			'playdate.pds',
			'playdate.pdt',
			'playdate.pdv',
			'playdate.pdz',
			'playdate.pft',
		]

		prepare: /* (project, product, inputs, outputs, input, output, explicitlyDependsOn) => */ {
			var cmds = []

			var pdcOutput = inputs['playdate.pdc-output'][0].filePath
			var sourceDir = product.Playdate.sdk.sourceDir

			var listActions = new JavaScriptCommand()
			listActions.description = 'compiling ' + PD.processPdcOutput(pdcOutput, sourceDir).join(' [' + product.name + ']\n')
			listActions.sourceCode = function () {}
			cmds.push(listActions)

			return cmds
		}
	}
}
