import importlib.util
import unittest
from pathlib import Path


MODULE_PATH = (
    Path(__file__).resolve().parents[2]
    / "tools"
    / "compiler"
    / "build_gfx950_tactic_catalog.py"
)
SPEC = importlib.util.spec_from_file_location("build_gfx950_tactic_catalog", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class UnlockedExperimentTest(unittest.TestCase):
    def test_only_explicit_zero_hash_all_experiment_artifact_is_unlocked(self) -> None:
        zero_hash = "0" * 64
        self.assertTrue(
            MODULE._is_unlocked_experiment(
                allow=True,
                locked_text_hash=zero_hash,
                member_maturities=["experiment", "experiment"],
            )
        )
        for allow, locked_hash, maturities in (
            (False, zero_hash, ["experiment"]),
            (True, "1" * 64, ["experiment"]),
            (True, zero_hash, ["verified"]),
            (True, zero_hash, ["experiment", "accepted"]),
            (True, zero_hash, []),
        ):
            with self.subTest(
                allow=allow, locked_hash=locked_hash, maturities=maturities
            ):
                self.assertFalse(
                    MODULE._is_unlocked_experiment(
                        allow=allow,
                        locked_text_hash=locked_hash,
                        member_maturities=maturities,
                    )
                )


if __name__ == "__main__":
    unittest.main()
