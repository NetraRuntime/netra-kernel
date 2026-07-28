from typing import Type

from transformers import (
    AutoImageProcessor,
    AutoProcessor,
    BaseImageProcessor,
    PretrainedConfig,
    ProcessorMixin,
)


def register_image_processor(
    config: Type[PretrainedConfig], image_processor: Type[BaseImageProcessor]
):
    """
    Register a customized HF image processor while removing the HF implementation.

    Text-only ROCm deployments may intentionally omit torchvision. Config modules are
    still imported eagerly, so leave their image processors unregistered in that case.
    """
    try:
        AutoImageProcessor.register(
            config, slow_image_processor_class=image_processor, exist_ok=True
        )
    except ImportError:
        pass


def register_processor(config: Type[PretrainedConfig], processor: Type[ProcessorMixin]):
    """
    register customized hf processor while removing hf impl
    """
    AutoProcessor.register(config, processor, exist_ok=True)
