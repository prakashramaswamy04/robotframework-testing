import sys
import unittest
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from libraries.quarter_utils import normalize_quarter_value


class QuarterUtilsTests(unittest.TestCase):
    def test_normalize_quarter_value_adds_current_year_when_missing(self) -> None:
        current_year = datetime.now().year
        self.assertEqual(normalize_quarter_value("Q2"), f"Q2 {current_year}")

    def test_normalize_quarter_value_preserves_existing_year(self) -> None:
        self.assertEqual(normalize_quarter_value("Q3 2024"), "Q3 2024")

    def test_normalize_quarter_value_handles_case_insensitivity(self) -> None:
        self.assertEqual(normalize_quarter_value("q4 2025"), "Q4 2025")


if __name__ == "__main__":
    unittest.main()
