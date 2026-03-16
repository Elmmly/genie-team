---
type: topic
title: "Build to learn: Viability for Genie Team"
status: pending
source: cataliva
approach: build-to-learn
dimension: "viability"
created: 2026-03-16
---

# Build to learn: Viability for Genie Team

## Hypothesis

We believe we can use an AI-driven system to transform a cluster of unstructured strategic context into a coherent, structured, first-draft build-to-learn brief. We believe this because our core mission is to apply AI to business process optimization, and our own discovery kickoff is a prime candidate for this optimization. If we are wrong, our own operational velocity will be bottlenecked by a manual, high-effort process, undermining our ability to rapidly test hypotheses.

## Why This Matters Now

The speed and quality of our build-to-learn cycles are the primary measure of our team's effectiveness. The initial step—transforming raw context and identified gaps into a focused, actionable brief—is currently a manual bottleneck. Solving this "blank page" problem for ourselves is critical to establishing the high-velocity workflow our team is designed for. If we don't build a scalable process for initiating our own work, every subsequent project will be delayed before it even begins.

This is a foundational, dogfooding opportunity. Our organization's purpose is to "empower innovators and accelerate the creation of impactful solutions" using AI. We must first apply this principle to our own core workflow. Successfully augmenting our brief-creation process will not only accelerate our work but also serve as the first validation of our broader thesis. This build gates the fundamental decision on how our team will operate: will we be tool-builders who leverage our own creations, or will we be dependent on traditional, manual processes?

## What We Already Know

*   **Validated Assumptions:** The six-part build-to-learn brief is an effective format for framing our work. The Genie Team model itself is predicated on building small, runnable software to validate hypotheses.
*   **JTBD / Pain Points:** A product strategist (or the team itself) needs to "kick off a discovery process." The primary pain is the significant time and cognitive load required to synthesize unstructured notes, data, and gaps into a focused, actionable plan.
*   **Organizational Context:** Our organization focuses on "AI-driven solutions for business process optimization." Our team's purpose is to "empower innovators and accelerate the creation of impactful solutions." The immediate gap we need to address is the "Discovery kickoff for Genie Team."
*   **Known Approaches:** The current state-of-the-art is manual synthesis by a product strategist. General-purpose LLMs can be used for ad-hoc summarization, but this lacks a repeatable, structured workflow tailored to our specific brief format.

## Capability to Validate

You need to create a capability that accepts a body of unstructured text detailing strategic context and a specific gap as input. As output, it must produce a complete, six-section build-to-learn brief in markdown that attempts to solve the "Discovery kickoff" problem.

The challenge is not simply to summarize text, but to synthesize it into the specific, discrete sections of our brief format. The system must be able to infer a falsifiable hypothesis, identify what is already known, propose a capability to validate, and articulate the strategic decision that the work unlocks. The goal is to build the smallest possible thing that can produce a draft brief from raw context, allowing us to assess if an AI-first approach is viable for our own workflow.

## Learning Goals

1.  **Hypothesis Formulation:** Running this on the "Genie Team Viability" context will show us if the system can generate a specific, falsifiable hypothesis that is relevant to the provided gap.
2.  **Structural Integrity:** The output will demonstrate whether the system can consistently generate all six required sections in the correct format, with content appropriate to each heading.
3.  **Contextual Extraction:** By comparing the generated "What We Already Know" section to the source text, we will learn how accurately the system can extract and categorize relevant facts without hallucinating or omitting critical information.
4.  **Strategic Synthesis:** Evaluating the generated "Capability to Validate" and "Decision This Unlocks" sections will tell us if the system can produce strategically sound, actionable proposals, or if the output is too generic to be useful.
5.  **Relevance to Gap:** We will learn if the system can correctly interpret the "Gaps Detected" input and frame the entire brief as a direct response to that specific problem.

## Decision This Unlocks

This build gates our internal operational strategy for initiating projects.

*   **If hypothesis supported** → We will invest in this capability as a core component of our internal toolkit. Generating a first-draft brief becomes the standard, automated first step for every new investigation, fundamentally accelerating our team's discovery process.
*   **If hypothesis refuted** → We will conclude that brief creation is, for now, a necessarily human-centric task requiring nuanced strategic synthesis beyond current AI capabilities. We will then resource the team with dedicated product strategy support, accepting the manual process as the current cost of high-quality discovery.
