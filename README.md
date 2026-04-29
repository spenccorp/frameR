# frameR <img src="man/figures/logo.png" align="right" height="139" alt="" />

> Measuring Emphasis Frames in Political Text Using Sentence Embeddings

[![R CMD Check](https://github.com/spenccorp/frameR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/spenccorp/frameR/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

`frameR` provides tools for measuring emphasis frames in political text
using transformer-based sentence embeddings and cosine similarity.
Rather than classifying sentences into frame categories — which measures
frame salience — `frameR` measures the semantic association between
issue-relevant discourse and theoretically specified frame categories.
This operationalizes emphasis frames as they are conceptualized in the
political communication literature: as semantic links between a core
issue and peripheral evaluative considerations.

The package implements a four-step pipeline:

1. **Embed** a corpus of text using a sentence embedding model
2. **Identify** issue-relevant sentences using keyword matching,
   semantic similarity, or both
3. **Specify** theoretically motivated frame categories as keyword sets
   and embed them
4. **Measure** frame strength as cosine similarity between issue discourse
   and frame keywords, with bootstrap uncertainty quantification and
   permutation-based significance testing

`frameR` is designed for cross-national and cross-lingual comparative
research. It accepts any sentence embedding model from the
`sentence-transformers` library and includes utilities for domain
adaptation to political text.

## Installation

```r
# Install from GitHub
devtools::install_github("spenccorp/frameR")
```

After installing, set up the Python environment once:

```r
library(frameR)
install_frameR()
# Restart R when prompted
```

## Quick Start

```r
library(frameR)

# Load the base embedding model
model <- load_model()

# Example corpus
sentences <- c(
  "Immigration is a burden on the welfare state.",
  "Immigrants take jobs from native workers.",
  "Our culture and values are under threat.",
  "We must protect our national identity.",
  "Border security is essential for public safety.",
  "Crime rates increase with illegal immigration.",
  "The economy suffers from uncontrolled migration.",
  "France cannot afford any more immigration."
)

years <- c(1997, 1997, 2002, 2002, 2012, 2012, 2017, 2017)

# Step 1: Embed the corpus
embeddings <- embed_corpus(sentences, model)

# Step 2: Identify immigration-relevant sentences
topic_mask <- identify_topic_sentences(
  sentences    = sentences,
  embeddings   = embeddings,
  anchor_words = c("immigration", "immigrant", "migration"),
  model        = model
)

# Step 3: Specify and embed frame categories
frame_categories <- list(
  Economic = c("economy", "jobs", "welfare", "employment"),
  Cultural = c("culture", "values", "identity", "tradition"),
  Security = c("crime", "border", "terrorism", "security")
)

keyword_embeddings <- embed_keywords(frame_categories, model)

# Step 4: Measure frame strength across periods
results <- measure_frames(
  embeddings         = embeddings,
  topic_mask         = topic_mask,
  keyword_embeddings = keyword_embeddings,
  periods            = list(
    Early = c(1997, 2002),
    Late  = c(2012, 2017)
  ),
  years              = years
)

# Inspect and plot results
print(results)
plot(results)
```

## Choosing an Embedding Model

`frameR` supports three model options:

```r
# Base model (default) - works for any text
model <- load_model("base")

# Any Hugging Face sentence-transformers model
model <- load_model("sentence-transformers/paraphrase-multilingual-mpnet-base-v2")

# A locally fine-tuned model
model <- load_model("path/to/your/model")
```

For political manifesto text, we recommend fine-tuning the base model
on a domain-relevant corpus before analysis. A model pre-trained on the
full [Comparative Manifesto Project](https://manifesto-project.wzb.eu/)
corpus will be made available on Hugging Face upon publication of the
accompanying methods paper.

## Frame Specification

Frame categories are researcher-specified and should be derived from
the substantive theoretical literature prior to analysis. Keywords
should be specified in the language of the target corpus.

We recommend assessing robustness to keyword specification by running
the analysis under baseline, broader, and stricter keyword sets:

```r
# Baseline
frames_baseline <- list(
  Economic = c("economy", "jobs", "welfare"),
  Cultural = c("culture", "values", "identity"),
  Security = c("crime", "border", "terrorism")
)

# Broader
frames_broader <- list(
  Economic = c("economy", "jobs", "welfare", "wages",
               "employment", "fiscal", "budget"),
  Cultural = c("culture", "values", "identity", "tradition",
               "nation", "heritage", "integration"),
  Security = c("crime", "border", "terrorism", "security",
               "illegal", "police", "violence")
)

# Stricter
frames_stricter <- list(
  Economic = c("welfare", "employment", "economy"),
  Cultural = c("culture", "tradition", "identity"),
  Security = c("terrorism", "security", "border")
)
```

## Output

`measure_frames()` returns a `frameR_results` object containing:

- **`summary`**: Bootstrap estimates of frame similarity with 95%
  confidence intervals for each frame category and period
- **`permutation_tests`**: Between-period differences with p-values
  from permutation tests
- **`ratios`**: Relative frame emphasis scores normalized within
  each period
- **`boot_results`**: Raw bootstrap distributions for custom analysis

`plot()` produces a three-panel figure showing absolute frame
similarity, relative frame emphasis, and between-period differences
with significance indicators.

## Citation

If you use `frameR` in your research please cite both the package
and the accompanying methods paper:

## License

MIT © Spencer Corp
