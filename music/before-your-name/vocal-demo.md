# Before Your Name - Vocal Demo Plan

## Provider

- Optional provider: ElevenLabs
- Status: Generated

## Prerequisites

- User approval for a live provider call: provided in chat
- Network approval: approved for this call
- API credentials: loaded from root `.env` variable `ELEVEN_LABS_API_KEY`
- Authorized voice selection: `George - Warm, Captivating Storyteller` (`JBFqnCBsd6RMkjVDRZzb`)

## Direction

The vocal should feel intimate, controlled, and slightly afraid of its own tenderness. The father is not performing for an audience; he is testing whether the room can hold what he cannot say directly.

## Source Lyric

- `music/before-your-name/lyrics.md`
- Provider input text: `music/before-your-name/elevenlabs-vocal-text.txt`

## Generation Command

```powershell
$env:ELEVENLABS_API_KEY = "<loaded from ELEVEN_LABS_API_KEY in .env>"
python .\.codex\skills\musical-song-production\scripts\generate_elevenlabs_vocal.py `
  --voice-id "JBFqnCBsd6RMkjVDRZzb" `
  --text-file ".\music\before-your-name\elevenlabs-vocal-text.txt" `
  --out ".\music\before-your-name\before-your-name-voice.mp3"
```

## Output

- `music/before-your-name/before-your-name-voice.mp3`

## Fail-Closed Status

Text-to-speech provider call completed successfully. This is a spoken vocal guide from TTS, not a final sung performance.

## Sung Demo Plan

- Provider: Eleven Music
- Composition plan: `music/before-your-name/eleven-music-plan.json`
- Target output: `music/before-your-name/before-your-name-eleven-music.mp3`
- Melody reference: `music/before-your-name/melody.md`
- Status: Generated
- Error record: `music/before-your-name/eleven-music-error.json` retained for history
- Limitation: Eleven Music can generate sung vocals from lyrics, style, structure, and section guidance, but it does not guarantee exact performance of the MIDI guide melody.

## Sung Demo Command

```powershell
$line = Get-Content '.\.env' | Where-Object { $_ -match '^ELEVEN_LABS_API_KEY=' } | Select-Object -First 1
$env:ELEVENLABS_API_KEY = ($line -split '=',2)[1].Trim().Trim('"').Trim("'")
python .\.codex\skills\musical-song-production\scripts\generate_eleven_music.py `
  --plan ".\music\before-your-name\eleven-music-plan.json" `
  --out ".\music\before-your-name\before-your-name-eleven-music.mp3"
```

## Sung Demo Output

- `music/before-your-name/before-your-name-eleven-music.mp3`

## Vocal-Only Stem For Cakewalk/Sonar

- Composition plan: `music/before-your-name/eleven-music-vocal-only-plan.json`
- Target output: `music/before-your-name/before-your-name-vocal-only.mp3`
- Intended use: import into Cakewalk/Sonar as an isolated vocal audio track over local MIDI/audio accompaniment.
- Status: Generated
- Alignment: full-track vocal stem includes intro space before the first vocal entrance.
