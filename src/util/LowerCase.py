import string


def addressToLower(address):
    if not address or address[0] == "0":
        # Already lowercase
        return address
    # 1HeLLo4uzjaLetFx6NH3PMwFP3qbRbTf3D -> 0hello4uzjaletfx6nh3pmwfp3qbrbtf3dlqf5lug
    case_int = sum([1 << i for i, c in enumerate(address) if c.isupper()])
    case_str = ""
    for _ in range(7):
        case_str += (string.ascii_lowercase + string.digits)[case_int % 36]
        case_int //= 36
    return "0" + address.lower()[1:] + case_str


def addressToFull(address):
    if not address or address[0] == "1":
        # Already full
        return address
    # 0hello4uzjaletfx6nh3pmwfp3qbrbtf3dlqf5lug -> 1HeLLo4uzjaLetFx6NH3PMwFP3qbRbTf3D
    case_str = address[-7:]
    case_int = sum([(string.ascii_lowercase + string.digits).index(c) * 36 ** i for i, c in enumerate(case_str)])
    address = "".join([c.upper() if case_int & (1 << i) else c for i, c in enumerate(address[:-7])])
    return "1" + address[1:]
