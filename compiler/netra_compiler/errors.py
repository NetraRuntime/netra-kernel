class NetraCompilerError(Exception):
    """Base class for actionable compiler errors."""


class ValidationError(NetraCompilerError):
    pass


class UnsupportedContract(NetraCompilerError):
    pass


class BuildUnavailable(NetraCompilerError):
    pass
