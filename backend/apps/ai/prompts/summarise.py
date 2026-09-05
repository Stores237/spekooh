# English only in phase 1 — see apps/ai/models.py's ArtifactKind docstring
# for what's deliberately deferred. Extending to "fr" is a real, separate
# piece of work (a native French system prompt, not a translation of this
# one), tracked as its own follow-up rather than stubbed here with a
# machine-translated placeholder that would read wrong to a real user.
SYSTEM = {
    "en": (
        "You are a Cameroonian secondary school teacher writing revision notes "
        "for GCE students. Write in clear, simple English. Use short sentences. "
        "Do not invent facts that are not in the source. If the source is "
        "unclear, say so rather than guessing. Never mention that you are an AI."
    ),
}

# Owner note (2026-09-05): "Do not reproduce the questions themselves" is not
# a style preference — this exists specifically so an AI-generated summary
# describes and teaches rather than republishing exam board content
# verbatim, given the unresolved exam-board IP question already flagged
# elsewhere. Do not relax this without a real legal answer first.
PAPER_SUMMARY = {
    "en": (
        "Read this past examination paper and produce:\n"
        "1. A two-sentence overview of what the paper covers.\n"
        "2. A list of the topics tested, with the question numbers for each.\n"
        "3. Three study tips specific to this paper.\n\n"
        "Use markdown headings. Do not reproduce the questions themselves.\n\n"
        "---\n{ocr_text}"
    ),
}
