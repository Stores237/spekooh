"""
Near-duplicate detection over OCR'd paper text. TF-IDF + cosine similarity
substitutes for a hosted embedding model per the plan's environment-forced
substitutions — no GPU/model download needed at this scale, and it's
swappable later behind this same DuplicateDetector interface.
"""

import abc
import dataclasses
import hashlib


def normalize_text(text: str) -> str:
    return " ".join(text.lower().split())


def exact_duplicate_hash(text: str) -> str:
    return hashlib.sha256(normalize_text(text).encode("utf-8")).hexdigest()


@dataclasses.dataclass(frozen=True)
class DuplicateMatch:
    candidate_id: int
    similarity: float


class DuplicateDetector(abc.ABC):
    @abc.abstractmethod
    def find_duplicate(self, text: str, candidates: list[tuple[int, str]]) -> DuplicateMatch | None:
        """Returns the best-matching candidate above the detector's threshold, or None."""
        raise NotImplementedError


class TfidfDuplicateDetector(DuplicateDetector):
    def __init__(self, threshold: float = 0.85):
        self.threshold = threshold

    def find_duplicate(self, text: str, candidates: list[tuple[int, str]]) -> DuplicateMatch | None:
        candidates = [(cid, ctext) for cid, ctext in candidates if ctext.strip()]
        if not text.strip() or not candidates:
            return None

        from sklearn.feature_extraction.text import TfidfVectorizer
        from sklearn.metrics.pairwise import cosine_similarity

        corpus = [text] + [ctext for _, ctext in candidates]
        matrix = TfidfVectorizer().fit_transform(corpus)
        similarities = cosine_similarity(matrix[0:1], matrix[1:])[0]

        best_index = similarities.argmax()
        best_score = float(similarities[best_index])
        if best_score < self.threshold:
            return None
        return DuplicateMatch(candidate_id=candidates[best_index][0], similarity=best_score)
