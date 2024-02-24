from abc import ABCMeta, abstractmethod

from amaranth.build import Platform as AmaranthPlatform

__all__ = ["Platform"]


class PlatformRegistry(ABCMeta):
    _registry = {}
    _build_targets = set()

    def __new__(mcls, name, bases, *args, **kwargs):
        cls = super().__new__(mcls, name, bases, *args, **kwargs)
        if bases:
            mcls._registry[cls.__name__] = cls
            if issubclass(cls, AmaranthPlatform) and cls is not AmaranthPlatform:
                mcls._build_targets.add(cls.__name__)
        return cls

    def __getitem__(cls, key):
        return cls._registry[key]()

    @property
    def build_targets(cls):
        return cls._build_targets


class Platform(metaclass=PlatformRegistry):
    simulation = False

    @property
    def freq(self):
        return self.default_clk_frequency

    @property
    @abstractmethod
    def default_clk_frequency(self):
        ...
