# Schloss Seifersdorf Calendar

This repository contains a calendar widget that displays upcoming events from a Google Calendar. The calendar data is automatically updated and can be embedded in any website.

## Overview

The system consists of:
- A GitHub Actions workflow that runs every 15 minutes to update the calendar
- A local script for manual updates and testing
- A simple HTML widget to display the calendar events

## Setup

### 1. Configure API Credentials

Copy the example environment file and add your credentials:

```bash
cp .env.example .env
```

Edit `.env` and add your values:
```bash
CALENDAR_ID=your_calendar_id_here
API_KEY=your_google_api_key_here
```

**Getting your credentials:**
- **CALENDAR_ID**: In Google Calendar, go to calendar settings and copy the Calendar ID (without the `@group.calendar.google.com` part)
- **API_KEY**: Create an API key in the [Google Cloud Console](https://console.cloud.google.com/) with Calendar API access enabled

### 2. Run the Update Script

Make the script executable (already done if you cloned this repo):
```bash
chmod +x update-calendar.sh
```

Run the script:
```bash
./update-calendar.sh
```

## Usage

### Basic Usage

Update the calendar and push changes:
```bash
./update-calendar.sh
```

### Options

**Dry Run Mode** - Test without committing or pushing:
```bash
./update-calendar.sh --dry-run
```

**Verbose Mode** - See detailed output:
```bash
./update-calendar.sh --verbose
```

**Combined** - Test with detailed output:
```bash
./update-calendar.sh --dry-run --verbose
```

**Help** - Show usage information:
```bash
./update-calendar.sh --help
```

## How It Works

1. **Fetches calendar data**: The script queries the Google Calendar API for the next 3 upcoming events
2. **Saves to JSON**: The events are saved to `calendar.json`
3. **Checks for changes**: Uses `git diff` to detect if the calendar data has changed
4. **Commits and pushes**: If changes are detected (and not in dry-run mode), the script commits and pushes to GitHub
5. **GitHub Pages**: The `calendar.json` file is served via GitHub Pages at:
   ```
   https://joergrosenkranz.github.io/schloss-seifersdorf-calendar/calendar.json
   ```

## Automated Updates

The GitHub Actions workflow (`.github/workflows/update-calendar.yml`) runs automatically every 15 minutes to keep the calendar up to date. The workflow does the same thing as the local script.

## Embedding the Calendar Widget

Include the calendar widget in your HTML:

```html
<div id="top3calendar"></div>
<script src="https://joergrosenkranz.github.io/schloss-seifersdorf-calendar/index.html"></script>
```

Or copy the script from `index.html` directly into your page.

## Troubleshooting

### Error: .env file not found
Create a `.env` file from the template:
```bash
cp .env.example .env
```
Then edit it and add your credentials.

### Error: CALENDAR_ID not set in .env
Open `.env` and add your Google Calendar ID.

### Error: API_KEY not set in .env
Open `.env` and add your Google API Key.

### Error: Failed to fetch calendar data (HTTP 400)
- Check that your `CALENDAR_ID` is correct
- Check that your `API_KEY` is valid
- Ensure the Calendar API is enabled in Google Cloud Console

### Error: Failed to fetch calendar data (HTTP 403)
- Your API key may not have permission to access the calendar
- Check that the calendar is public or your API key has access

### Error: Failed to push changes to remote repository
- Check that you have push permissions to the repository
- Ensure you have git credentials configured
- Try running `git push` manually to see the detailed error

## Files

- `update-calendar.sh` - Local script to update the calendar
- `.env.example` - Template for environment variables
- `calendar.json` - Current calendar data (auto-generated)
- `index.html` - Calendar widget HTML/JavaScript
- `.github/workflows/update-calendar.yml` - Automated update workflow

## Requirements

- `bash` - Shell script interpreter
- `curl` - For making HTTP requests
- `git` - For committing and pushing changes
- `python3` - For JSON validation (standard on macOS/Linux)
- Google Calendar API credentials (Calendar ID and API Key)

## License

This project is open source and available for use.
