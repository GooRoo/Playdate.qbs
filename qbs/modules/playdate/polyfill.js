function partial(func) {
	var partialArgs = Array.prototype.slice.call(arguments, 1)

	return function () {
		var args = partialArgs.concat(Array.prototype.slice.call(arguments))
		return func.apply(this, args)
	}
}

function isUndefined(value) {
	return typeof value === 'undefined'
}

function isMinusOne(value) {
	return value === -1
}
