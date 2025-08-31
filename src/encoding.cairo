#[inline(always)]
fn get_base64_char_set() -> Span<u8> {
    let mut result = array![
        'A',
        'B',
        'C',
        'D',
        'E',
        'F',
        'G',
        'H',
        'I',
        'J',
        'K',
        'L',
        'M',
        'N',
        'O',
        'P',
        'Q',
        'R',
        'S',
        'T',
        'U',
        'V',
        'W',
        'X',
        'Y',
        'Z',
        'a',
        'b',
        'c',
        'd',
        'e',
        'f',
        'g',
        'h',
        'i',
        'j',
        'k',
        'l',
        'm',
        'n',
        'o',
        'p',
        'q',
        'r',
        's',
        't',
        'u',
        'v',
        'w',
        'x',
        'y',
        'z',
        '0',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        '+',
        '/',
    ];
    result.span()
}

pub fn bytes_base64_encode(_bytes: ByteArray) -> ByteArray {
    encode_bytes(_bytes, get_base64_char_set())
}


fn encode_bytes(mut bytes: ByteArray, base64_chars: Span<u8>) -> ByteArray {
    let mut result: ByteArray = "";
    if bytes.len() == 0 {
        return result;
    }
    let mut p: u8 = 0;
    let c = bytes.len() % 3;
    if c == 1 {
        p = 2;
        bytes.append_byte(0_u8);
        bytes.append_byte(0_u8);
    } else if c == 2 {
        p = 1;
        bytes.append_byte(0_u8);
    }

    let mut i = 0;
    let bytes_len = bytes.len();
    let last_iteration = bytes_len - 3;
    loop {
        if i == bytes_len {
            break;
        }
        let n: u32 = (bytes.at(i).unwrap()).into()
            * 65536 | (bytes.at(i + 1).unwrap()).into()
            * 256 | (bytes.at(i + 2).unwrap()).into();
        let e1 = (n / 262144) & 63;
        let e2 = (n / 4096) & 63;
        let e3 = (n / 64) & 63;
        let e4 = n & 63;

        if i == last_iteration {
            if p == 2 {
                result.append_byte(*base64_chars[e1]);
                result.append_byte(*base64_chars[e2]);
                result.append_byte('=');
                result.append_byte('=');
            } else if p == 1 {
                result.append_byte(*base64_chars[e1]);
                result.append_byte(*base64_chars[e2]);
                result.append_byte(*base64_chars[e3]);
                result.append_byte('=');
            } else {
                result.append_byte(*base64_chars[e1]);
                result.append_byte(*base64_chars[e2]);
                result.append_byte(*base64_chars[e3]);
                result.append_byte(*base64_chars[e4]);
            }
        } else {
            result.append_byte(*base64_chars[e1]);
            result.append_byte(*base64_chars[e2]);
            result.append_byte(*base64_chars[e3]);
            result.append_byte(*base64_chars[e4]);
        }

        i += 3;
    }

    result
}

#[cfg(test)]
mod tests {
    use super::{bytes_base64_encode, get_base64_char_set};

    #[test]
    fn test_base64_empty_string() {
        let input = "";
        let encoded = bytes_base64_encode(input);
        assert(encoded.len() == 0, 'Empty encodes to empty');
    }

    #[test]
    fn test_base64_single_char() {
        let input = "A";
        let encoded = bytes_base64_encode(input);
        // "A" should encode to "QQ=="
        assert(encoded.len() == 4, 'Single char len 4');
        assert(encoded == "QQ==", 'A encodes to QQ==');
    }

    #[test]
    fn test_base64_two_chars() {
        let input = "AB";
        let encoded = bytes_base64_encode(input);
        // "AB" should encode to "QUI="
        assert(encoded.len() == 4, 'Two chars len 4');
        assert(encoded == "QUI=", 'AB encodes to QUI=');
    }

    #[test]
    fn test_base64_three_chars() {
        let input = "ABC";
        let encoded = bytes_base64_encode(input);
        // "ABC" should encode to "QUJD"
        assert(encoded.len() == 4, 'Three chars len 4');
        assert(encoded == "QUJD", 'ABC encodes to QUJD');
    }

    #[test]
    fn test_base64_hello_world() {
        let input = "Hello World";
        let encoded = bytes_base64_encode(input);
        // "Hello World" should encode to "SGVsbG8gV29ybGQ="
        assert(encoded.len() == 16, 'Hello World len 16');
        assert(encoded == "SGVsbG8gV29ybGQ=", 'Hello World check');
    }

    #[test]
    fn test_base64_padding_cases() {
        // Test case where length % 3 == 1 (requires == padding)
        let input1 = "Sure";
        let encoded1 = bytes_base64_encode(input1);
        assert(encoded1.len() % 4 == 0, 'Mult of 4');

        // Test case where length % 3 == 2 (requires = padding)
        let input2 = "Sure!";
        let encoded2 = bytes_base64_encode(input2);
        assert(encoded2.len() % 4 == 0, 'Mult of 4');

        // Test case where length % 3 == 0 (no padding)
        let input3 = "Sure!!";
        let encoded3 = bytes_base64_encode(input3);
        assert(encoded3.len() % 4 == 0, 'Mult of 4');
    }

    #[test]
    fn test_base64_charset() {
        let charset = get_base64_char_set();
        assert(charset.len() == 64, 'Charset 64 chars');
        assert(*charset[0] == 'A', 'First is A');
        assert(*charset[25] == 'Z', 'Char 25 is Z');
        assert(*charset[26] == 'a', 'Char 26 is a');
        assert(*charset[51] == 'z', 'Char 51 is z');
        assert(*charset[52] == '0', 'Char 52 is 0');
        assert(*charset[61] == '9', 'Char 61 is 9');
        assert(*charset[62] == '+', 'Char 62 is +');
        assert(*charset[63] == '/', 'Char 63 is /');
    }

    #[test]
    fn test_base64_json_string() {
        // Test encoding a JSON-like string
        let input = "{\"name\":\"test\"}";
        let encoded = bytes_base64_encode(input);
        assert(encoded.len() > 0, 'JSON encodes');
        assert(encoded.len() % 4 == 0, 'Mult of 4');
    }

    #[test]
    fn test_base64_lengths() {
        // Test various input lengths
        let input1 = "x";
        let encoded1 = bytes_base64_encode(input1);
        assert(encoded1.len() == 4, 'Len 1 gives 4');

        let input2 = "xy";
        let encoded2 = bytes_base64_encode(input2);
        assert(encoded2.len() == 4, 'Len 2 gives 4');

        let input3 = "xyz";
        let encoded3 = bytes_base64_encode(input3);
        assert(encoded3.len() == 4, 'Len 3 gives 4');

        let input4 = "xyzw";
        let encoded4 = bytes_base64_encode(input4);
        assert(encoded4.len() == 8, 'Len 4 gives 8');
    }
}
