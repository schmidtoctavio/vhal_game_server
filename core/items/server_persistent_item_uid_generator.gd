class_name ServerPersistentItemUidGenerator
extends RefCounted


static func generate_uuid_v4() -> String:
	var crypto := Crypto.new()

	var bytes := crypto.generate_random_bytes(
		16
	)


	if bytes.size() != 16:
		return ""


	# UUID v4.
	bytes[6] = (
		(bytes[6] & 0x0F)
		|
		0x40
	)

	# RFC 4122 variant.
	bytes[8] = (
		(bytes[8] & 0x3F)
		|
		0x80
	)


	var hex := ""


	for byte_value: int in bytes:
		hex += (
			"%02x"
			%
			byte_value
		)


	return (
		hex.substr(0, 8)
		+
		"-"
		+
		hex.substr(8, 4)
		+
		"-"
		+
		hex.substr(12, 4)
		+
		"-"
		+
		hex.substr(16, 4)
		+
		"-"
		+
		hex.substr(20, 12)
	)


static func is_valid_uuid(
	value: String
) -> bool:
	var normalized := (
		value
		.strip_edges()
		.to_lower()
	)


	if normalized.length() != 36:
		return false


	if (
		normalized[8] != "-"
		or
		normalized[13] != "-"
		or
		normalized[18] != "-"
		or
		normalized[23] != "-"
	):
		return false


	const HEX := "0123456789abcdef"


	for index in range(
		normalized.length()
	):
		if index in [
			8,
			13,
			18,
			23,
		]:
			continue


		if HEX.find(
			normalized[index]
		) == -1:
			return false


	return true
