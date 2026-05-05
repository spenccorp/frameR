# frameR core Python module
# Called internally by R functions via reticulate
# Do not call directly

import numpy as np
import random
from sklearn.metrics.pairwise import cosine_similarity

# ============================================================
# MODEL LOADING
# ============================================================

def load_model(model_name="spenccorp/frameR-marpor"):
    from sentence_transformers import SentenceTransformer
    
    if model_name == "base":
        model_name = "sentence-transformers/paraphrase-multilingual-mpnet-base-v2"
    
    model = SentenceTransformer(model_name)
    return model


# ============================================================
# CORPUS EMBEDDING
# ============================================================

def embed_corpus(sentences, model, batch_size=8):
    """
    Embed all sentences in a corpus.
    Embeddings are computed once and stored for downstream use.

    Parameters
    ----------
    sentences : list of str
        All sentences in the corpus.
    model : SentenceTransformer
        Loaded embedding model.
    batch_size : int
        Number of sentences per batch. Reduce if memory limited.

    Returns
    -------
    numpy.ndarray
        Matrix of shape (n_sentences, embedding_dim).
    """
    embeddings = model.encode(
        sentences,
        batch_size=batch_size,
        show_progress_bar=True,
        convert_to_numpy=True,
        normalize_embeddings=False
    ).astype(np.float32)

    return embeddings


# ============================================================
# TOPIC SENTENCE IDENTIFICATION
# ============================================================

def identify_topic_sentences(sentences, embeddings, anchor_words,
                              model, threshold=0.5, method="both"):
    """
    Identify sentences relevant to a topic of interest.

    Parameters
    ----------
    sentences : list of str
        All sentences in the corpus.
    embeddings : numpy.ndarray
        Pre-computed sentence embeddings.
    anchor_words : list of str
        Keywords defining the topic of interest.
    model : SentenceTransformer
        Loaded embedding model.
    threshold : float
        Cosine similarity threshold for semantic matching.
        Only used when method is "similarity" or "both".
    method : str
        One of "keyword", "similarity", or "both".
        "keyword"    : flag sentences containing anchor words only.
        "similarity" : flag sentences above similarity threshold only.
        "both"       : union of keyword and similarity (recommended).

    Returns
    -------
    numpy.ndarray
        Boolean array of length n_sentences.
    """
    import re

    sentences = list(sentences)
    n = len(sentences)

    keyword_mask = np.zeros(n, dtype=bool)
    similarity_mask = np.zeros(n, dtype=bool)

    # Keyword matching
    if method in ("keyword", "both"):
        pattern = '|'.join([re.escape(w) for w in anchor_words])
        keyword_mask = np.array([
            bool(re.search(pattern, s, re.IGNORECASE))
            for s in sentences
        ])

    # Semantic similarity
    if method in ("similarity", "both"):
        anchor_embeddings = model.encode(
            anchor_words,
            convert_to_numpy=True
        )
        anchor_mean = anchor_embeddings.mean(axis=0, keepdims=True)
        scores = cosine_similarity(embeddings, anchor_mean).flatten()
        similarity_mask = scores >= threshold

    if method == "keyword":
        return keyword_mask
    elif method == "similarity":
        return similarity_mask
    else:
        return keyword_mask | similarity_mask


# ============================================================
# FRAME KEYWORD EMBEDDING
# ============================================================

def embed_keywords(frame_categories, model):
    """
    Embed frame category keywords.

    Parameters
    ----------
    frame_categories : dict
        Named dictionary where keys are frame category names
        and values are lists of keywords.
        Example: {"Economic": ["jobs", "welfare"],
                  "Cultural": ["values", "identity"]}
    model : SentenceTransformer
        Loaded embedding model.

    Returns
    -------
    dict
        Dictionary mapping frame category names to
        numpy arrays of keyword embeddings.
    """
    keyword_embeddings = {}

    for category, keywords in frame_categories.items():
        embeddings = model.encode(
            list(keywords),
            convert_to_numpy=True
        ).astype(np.float32)
        keyword_embeddings[category] = embeddings

    return keyword_embeddings


# ============================================================
# FRAME SIMILARITY COMPUTATION
# ============================================================

def compute_frame_similarities(doc_embeddings, keyword_embeddings):
    """
    Compute mean cosine similarity between document embeddings
    and each frame category's keyword embeddings.

    Parameters
    ----------
    doc_embeddings : numpy.ndarray
        Embeddings of topic-relevant sentences.
    keyword_embeddings : dict
        Output of embed_keywords().

    Returns
    -------
    dict
        Dictionary mapping frame category names to
        cosine similarity scores.
    """
    mean_embedding = doc_embeddings.mean(axis=0, keepdims=True)

    frame_similarities = {}
    for category, kw_embeddings in keyword_embeddings.items():
        sims = cosine_similarity(mean_embedding, kw_embeddings).flatten()
        frame_similarities[category] = float(sims.mean())

    return frame_similarities


# ============================================================
# BOOTSTRAP INFERENCE
# ============================================================

def bootstrap_frames(doc_embeddings, keyword_embeddings,
                     n_boot=10000, seed=42):
    """
    Bootstrap frame similarity estimates for a single period.

    Parameters
    ----------
    doc_embeddings : numpy.ndarray
        Embeddings of topic-relevant sentences for this period.
    keyword_embeddings : dict
        Output of embed_keywords().
    n_boot : int
        Number of bootstrap iterations.
    seed : int
        Random seed for reproducibility.

    Returns
    -------
    dict
        Dictionary mapping frame category names to arrays
        of bootstrap similarity estimates.
    """
    np.random.seed(seed)
    n_docs = len(doc_embeddings)

    boot_results = {cat: [] for cat in keyword_embeddings.keys()}

    for _ in range(n_boot):
        indices = np.random.choice(n_docs, size=n_docs, replace=True)
        boot_embeddings = doc_embeddings[indices]
        sims = compute_frame_similarities(boot_embeddings, keyword_embeddings)
        for cat, sim in sims.items():
            boot_results[cat].append(sim)

    # Convert to arrays
    boot_results = {cat: np.array(vals) for cat, vals in boot_results.items()}

    return boot_results


def summarise_bootstrap(boot_results, period_name):
    """
    Compute summary statistics from bootstrap results.

    Parameters
    ----------
    boot_results : dict
        Output of bootstrap_frames().
    period_name : str
        Label for this period, used in output.

    Returns
    -------
    list of dict
        One dictionary per frame category containing
        mean, sd, and 95% confidence interval.
    """
    summary = []

    for cat, values in boot_results.items():
        summary.append({
            'period': period_name,
            'frame': cat,
            'mean': float(values.mean()),
            'sd': float(values.std()),
            'ci_lower': float(np.percentile(values, 2.5)),
            'ci_upper': float(np.percentile(values, 97.5)),
            'n_boot': len(values)
        })

    return summary


# ============================================================
# PERMUTATION TEST
# ============================================================

def permutation_test(boot_results_1, boot_results_2,
                     n_permutations=10000, seed=42):
    """
    Test whether two periods differ significantly in frame similarity.

    Parameters
    ----------
    boot_results_1 : dict
        Bootstrap results for period 1. Output of bootstrap_frames().
    boot_results_2 : dict
        Bootstrap results for period 2. Output of bootstrap_frames().
    n_permutations : int
        Number of permutation draws.
    seed : int
        Random seed for reproducibility.

    Returns
    -------
    list of dict
        One dictionary per frame category containing the observed
        difference, p-value, and significance label.
    """
    np.random.seed(seed)
    results = []

    for cat in boot_results_1.keys():
        vals_1 = boot_results_1[cat]
        vals_2 = boot_results_2[cat]

        observed_diff = float(vals_2.mean() - vals_1.mean())

        pooled = np.concatenate([vals_1, vals_2])
        n1 = len(vals_1)

        perm_diffs = []
        for _ in range(n_permutations):
            np.random.shuffle(pooled)
            perm_diffs.append(pooled[n1:].mean() - pooled[:n1].mean())

        perm_diffs = np.array(perm_diffs)
        p_value = float((np.abs(perm_diffs) >= np.abs(observed_diff)).mean())

        if p_value < 0.001:
            sig = "***"
        elif p_value < 0.01:
            sig = "**"
        elif p_value < 0.05:
            sig = "*"
        else:
            sig = "ns"

        results.append({
            'frame': cat,
            'difference': observed_diff,
            'p_value': p_value,
            'significance': sig
        })

    return results


# ============================================================
# RELATIVE FRAME EMPHASIS
# ============================================================

def compute_ratios(boot_results):
    """
    Compute relative frame emphasis as proportion of total
    frame similarity at each bootstrap iteration.

    Parameters
    ----------
    boot_results : dict
        Output of bootstrap_frames().

    Returns
    -------
    dict
        Dictionary mapping frame category names to arrays
        of relative emphasis scores (proportions summing to 1).
    """
    categories = list(boot_results.keys())

    all_values = np.array([boot_results[cat] for cat in categories])
    totals = all_values.sum(axis=0)

    ratio_results = {}
    for i, cat in enumerate(categories):
        ratio_results[cat] = all_values[i] / totals

    return ratio_results


def summarise_ratios(ratio_results, period_name):
    """
    Compute summary statistics from ratio results.

    Parameters
    ----------
    ratio_results : dict
        Output of compute_ratios().
    period_name : str
        Label for this period.

    Returns
    -------
    list of dict
        One dictionary per frame category.
    """
    summary = []

    for cat, values in ratio_results.items():
        summary.append({
            'period': period_name,
            'frame': cat,
            'mean_ratio': float(values.mean()),
            'sd_ratio': float(values.std()),
            'ci_lower': float(np.percentile(values, 2.5)),
            'ci_upper': float(np.percentile(values, 97.5))
        })

    return summary
