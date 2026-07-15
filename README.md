## MLB Matchup Prediction Engine
A full‑stack baseball analytics platform that generates daily MLB matchup predictions using automated data pipelines, dynamic benchmarks, player‑level analysis, and an explainable scoring engine.

This project is the next evolution of the original R Shiny application, rebuilt as a modern React + FastAPI web application backed by a PostgreSQL analytics database and fully automated ETL pipelines.

## Overview
The MLB Matchup Prediction Engine evaluates daily baseball games using only information available before first pitch.

Instead of relying on season-long team stats, the system builds a game-specific environment using:

Confirmed starting lineups

Starting pitcher profiles

Bullpen availability

Matchup splits

Pitch-type interactions

Park factors

Dynamic league benchmarks

The result is an explainable prediction system where every matchup score can be broken down into individual components.

## System Architecture
Data Sources → ETL Pipelines → PostgreSQL → Benchmark Engine → Matchup Engine → FastAPI → React Frontend

Key Components
Automated ETL Pipelines (Python + GitHub Actions)

Statcast data

MLB Stats API

ESPN odds

Park factors

PostgreSQL Analytics Database

Player stats

Team metrics

Historical matchup environments

Dynamic Benchmark Engine (R)

Daily league-relative benchmarks

Feature weighting

Game-Day Matchup Engine

Lineup aggregation

Pitcher evaluation

Bullpen analysis

Contextual adjustments

FastAPI Backend

REST endpoints for matchups, pitchers, batting, and historical data

React Frontend

Interactive dashboards

Pitcher analysis

Batting analysis

Scoring breakdowns

## Prediction Model
Each matchup is scored using weighted components:

Starting Pitcher Score

Team Batting Score

Bullpen & Pitching Depth Score

Handedness & Pitch-Type Matchups

Park & Contextual Adjustments

Scores are converted into win probabilities and displayed in the frontend.

## Automated Pipelines
Daily and hourly GitHub Actions workflows:

Daily ingestion of MLB data

Hourly lineup detection

Benchmark updates

Database maintenance

Game environment generation

All predictions use only pre-game data to ensure accurate historical evaluation.

## FastAPI Endpoints
Current endpoints include:

/matchups — daily matchup predictions

/pitchers — pitcher-level analysis

/batting — team offensive profiles

/historical — stored matchup environments (in development)

## React Frontend
Features:

Daily matchup dashboard

Pitcher comparison view

Batting analysis view

Scoring breakdowns

Data export

Historical browsing (in development)

## Tech Stack
Data Engineering: Python, Pandas, SQLAlchemy, PostgreSQL
Analysis: R, statistical modeling, benchmark generation
Backend: FastAPI, REST APIs
Frontend: React, JavaScript
Infrastructure: GitHub Actions, automated ETL, containerization (planned)
