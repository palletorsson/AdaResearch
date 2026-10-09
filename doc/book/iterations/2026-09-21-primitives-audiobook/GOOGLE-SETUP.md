# Connect Google speech

The narration is ready: ten Primitives halls and one closing notes track, 12,228 words. The audio edition is now available on [the audiobook page](index.html).

1. Sign in at [Google AI Studio — API keys](https://aistudio.google.com/api-keys).
2. Click **Create API key**, name it **Ada audiobook**, and select a project you own. AI Studio can provide a default project for a new account. Existing Cloud projects may need importing first.
3. Copy the key. Run `tools/setup_google_speech.cmd` from this repository, or paste it into the **Ada Research — Google speech setup** window if already open. This is a local, masked field, not a website form or chat message.
4. Save it, then tell Codex **key saved**. The next step is a short opening sample.

The key is encrypted with Windows DPAPI under `%LOCALAPPDATA%/AdaResearch/speech/gemini-key.dpapi`. It is bound to your Windows user and stays outside the repository. Saving it makes no Google request. An existing GEMINI_API_KEY or GOOGLE_API_KEY environment variable takes precedence over that file.

Google currently lists a free tier for Gemini 3.1 Flash TTS Preview. Start with that for the sample; setup does not enable billing. If the free quota is exhausted, the generator stops and retains completed passages. Paid use at the published rate is approximately $0.03 per minute of generated audio plus a small text-input charge. For 12,228 words at 145 words/minute, one clean pass would be about 84 minutes and $2.55; this is an estimate, and retries or a different pace change it. [Google pricing](https://ai.google.dev/gemini-api/docs/pricing#gemini-3.1-flash-tts-preview)

## Local commands

Run from the AdaResearch_46 repository:

```powershell
python tools/google_audiobook.py setup --gui
python tools/google_audiobook.py status
python tools/google_audiobook.py plan
python tools/google_audiobook.py sample
python tools/google_audiobook.py render
```

`status` reports presence only; it does not reveal the key or claim it works. `plan` checks the frozen source hashes and preserves all spoken words across chunk boundaries, without contacting Google. `sample` sends only the opening passage. `render` sends all eleven prepared tracks and makes individual MP3s plus a continuous MP3. It uses the existing prepared transcripts; it does not edit final.md.

Outputs go under `google/gemini-3.1-flash-tts-preview-Sulafat/` here. The default voice is Sulafat with a warm, thoughtful, unhurried direction. Change it with `--voice NAME`; voice, model and prompt changes use separate cached audio. Completed passages are retained for resuming. Google supplies pauses within passages; the transcript's exact pause_ms values are not applied by this renderer. Chapter and chunk joins have explicit silence.

Technical validation rejects incomplete responses, incompatible audio and implausible durations. It cannot establish faithful pronunciation or exact spoken wording: the sample and final tracks still need listening. There is no background render or automatic billing change. All speech is synthetic.

Implementation references: [Google speech generation](https://ai.google.dev/gemini-api/docs/speech-generation), [API key setup](https://ai.google.dev/gemini-api/docs/api-key), [Interactions API](https://ai.google.dev/api/interactions-api). Checked 21 September 2026.
