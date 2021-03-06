# Shortcuts for native object methods
objectRef = new ->
toString = objectRef.toString


# Identifies where in a sequential list a new value should be added.
sortedIndex = (array, candidate, iterator) ->
    iterator ?= (value) -> value
    value = iterator candidate

    low = 0
    high = array.length

    while (low < high)
      mid = (low + high) >> 1
      if iterator(array[mid]) < value then low = mid + 1 else high = mid

    return low

arrayIndex = [].indexOf or (item) ->
    arr = @
    for arrItem, index in arr
        return index if arrItem is item
    return -1

isNumber = (value) ->
    typeof value is 'number' or toString.call(value) is '[object Number]'

isFinite = (value) ->
    window.isFinite(value) and not window.isFinite(parseFloat(value))

isArray = (value) ->
    toString.call(value) is '[object Array]'

@Humanize = {}

# Converts a large integer to a friendly text representation.
@Humanize.intword = (number, charWidth, decimals) ->
    number = parseInt number, 10

    return @intcomma(number) if number.toString().length <= charWidth

    divisorList = [1000, 1000000, 1000000000]
    unitList = ["k", "M", "B"]

    divisorIndex = arrayIndex.call(divisorList, number)
    if divisorIndex is -1
        divisorIndex = sortedIndex(divisorList, number) - 1
    divisor = divisorList[divisorIndex]

    baseStr = ((number / divisor) + "")[0...charWidth]
    decimalStr = baseStr.split('.')[1]
    decimals ?= decimalStr? and parseInt(decimalStr, 10) and decimalStr.length or 0

    @intcomma(baseStr, decimals) + unitList[divisorIndex]

# Converts an integer to a string containing commas every three digits.
@Humanize.intcomma = (number, decimals = 0) ->
    @formatNumber number, decimals

# Formats the value like a 'human-readable' file size (i.e. '13 KB', '4.1 MB', '102 bytes', etc).
@Humanize.filesize = (filesize) ->
    if filesize >= 1073741824
        sizeStr = @formatNumber(filesize / 1073741824, 2, "") + " GB"
    else if filesize >= 1048576
        sizeStr = @formatNumber(filesize / 1048576, 2, "") + " MB"
    else if filesize >= 1024
        sizeStr = @formatNumber(filesize / 1024, 0) + " KB"
    else
        sizeStr = @formatNumber(filesize, 0) + " bytes"

    sizeStr

# Formats a number to a human-readable string.
# Localize by overriding the precision, thousand and decimal arguments.
@Humanize.formatNumber = (number, precision = 0, thousand = ",", decimal = ".") ->

    # Create some private utility functions to make the computational
    # code that follows much easier to read.

    firstComma = (number, thousand, position) =>
        if position then number.substr(0, position) + thousand else ""

    commas = (number, thousand, position) =>
        number.substr(position).replace /(\d{3})(?=\d)/g, "$1" + thousand

    decimals = (number, decimal, usePrecision) =>
        if usePrecision then decimal + @toFixed(Math.abs(number), usePrecision).split(".")[1] else ""

    usePrecision = @normalizePrecision precision

    # Do some calc
    negative = number < 0 and "-" or ""
    base = parseInt(@toFixed(Math.abs(number or 0), usePrecision), 10) + ""
    mod = if base.length > 3 then base.length % 3 else 0

    # Format the number
    negative +
    firstComma(base, thousand, mod) +
    commas(base, thousand, mod) +
    decimals(number, decimal, usePrecision)

# Fixes binary rounding issues (eg. (0.615).toFixed(2) === "0.61")
@Humanize.toFixed = (value, precision) ->
    precision ?= @normalizePrecision precision, 0
    power = Math.pow 10, precision

    # Multiply up by precision, round accurately, then divide and use native toFixed()
    (Math.round(value * power) / power).toFixed precision

# Ensures precision value is a positive integer
@Humanize.normalizePrecision = (value, base) ->
    value = Math.round Math.abs value
    if isNaN(value) then base else value

# Converts an integer to its ordinal as a string.
@Humanize.ordinal = (value) ->
    number = parseInt value, 10

    return value if number is 0

    specialCase = number % 100
    return number + "th" if specialCase in [11, 12, 13]

    leastSignificant = number % 10
    switch leastSignificant
        when 1
            end = "st"
        when 2
            end = "nd"
        when 3
            end = "rd"
        else
            end = "th"

    return number + end

# Interprets numbers as occurences. Also accepts an optional array/map of overrides.
@Humanize.times = (value, overrides={}) ->
    if isFinite(value) and value >= 0
        number = parseFloat value
        switch number
            when 0
                result = overrides[0]? or 'never'
            when 1
                result = overrides[1]? or 'once'
            when 2
                result = overrides[2]? or 'twice'
            else
                result = (overrides[number] or number) + " times"

    result

# Returns the plural version of a given word if the value is not 1. The default suffix is 's'.
@Humanize.pluralize = (number, singular, plural) ->
    return unless number? and singular?

    plural ?= singular + "s"

    if parseInt(number, 10) is 1 then singular else plural

# Truncates a string if it is longer than the specified number of characters (inclusive). Truncated strings will end with a translatable ellipsis sequence ("…").
@Humanize.truncate = (str, length, ending) ->
    length ?= 100
    ending ?= "..."

    if str.length > length
        str.substring(0, length - ending.length) + ending
    else
        str

# Truncates a string after a certain number of words.
@Humanize.truncatewords = (string, length) ->
    array = string.split " "
    result = ""
    i = 0

    while i < length
        if array[i]?
            result += array[i] + " "

        i++

    result += "..." if array.length > length

# Truncates a number to an upper bound.
@Humanize.truncatenumber = (num, bound, ending) ->
    bound ?= 100
    ending ?= "+"
    result = null

    if isFinite(num) and isFinite(bound)
        result = bound + ending if num > bound

    (result or num).toString()

# Converts a list of items to a human readable string with an optional limit.
@Humanize.oxford = (items, limit, limitStr) ->
    numItems = items.length

    if numItems < 2
        return "#{items}"

    else if numItems is 2
        return items.join ' and '

    else if limit? and numItems > limit
        extra = numItems - limit
        limitIndex = limit
        limitStr ?= ", and #{extra} #{@pluralize(extra, 'other')}"

    else
        limitIndex = -1
        limitStr = ", and #{items[numItems - 1]}"

    items.slice(0, limitIndex).join(', ') + limitStr

# Describes how many times an item appears in a list
@Humanize.frequency = (list, verb) ->
    return unless isArray(list)

    len = list.length
    times = @times len

    if len is 0
        str = "#{times} #{verb}"
    else
        str = "#{verb} #{times}"

    str

# Converts newlines to <br/> tags
@Humanize.nl2br = (string, replacement) ->
    replacement ?= '<br/>'
    string.replace /\n/g, replacement

# Converts <br/> tags to newlines
@Humanize.br2nl = (string, replacement) ->
    replacement ?= '\r\n'
    string.replace /\<br\s*\/?\>/g, replacement

# Capitalizes first letter in a string
@Humanize.capitalize = (string) ->
    string.charAt(0).toUpperCase() + string.slice(1)

# Capitalizes the first letter of each word in a string
@Humanize.titlecase = (string) ->
    string.replace /(?:^|\s)\S/g, (a) -> a.toUpperCase()
