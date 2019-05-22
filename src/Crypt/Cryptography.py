from lib import pybitcointools as btctools

# Must be defined before importing CryptBitcoin
class WrongCryptoError(Exception):
    pass
def newSeed():  # Random 256-bit key
    return btctools.random_key()

from Crypt import CryptBitcoin

# Known cryptographies
_cryptographies = {}
def registerCrypto(name, crypto):
    _cryptographies[name] = crypto
registerCrypto("Bitcoin", CryptBitcoin)

def getCryptographies():
    return _cryptographies.keys()


def _byName(func_name):
    def f(crypto, *args, **kwargs):
        if crypto in _cryptographies:
            return getattr(_cryptographies[crypto], func_name)(*args, **kwargs)
        else:
            raise ValueError(f"Unknown cryptography '{crypto}'")
    return f

def _any(func_name, err):
    def f(*args, **kwargs):
        for crypto in _cryptographies.values():
            try:
                return getattr(crypto, func_name)(*args, **kwargs)
            except WrongCryptoError:
                continue
        if isinstance(err, Exception):
            raise err
        else:
            return err
    return f

newPrivatekey = _byName("newPrivatekey")
hdPrivatekey = _byName("hdPrivatekey")
privatekeyToAddress = _any("privatekeyToAddress", False)
sign = _any("sign", None)

def verify(data, valid_address, sign):
    if not sign:
        return False
    f = _any("verify", ValueError("Invalid signature"))
    return f(data, valid_address, sign)