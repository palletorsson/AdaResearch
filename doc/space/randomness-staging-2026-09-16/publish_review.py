"""Publish this completed local review to the user's local encyclopedia."""
import pathlib
import shutil

ROOT = pathlib.Path(__file__).resolve().parents[3]
source = ROOT/'doc/research/possible-bodies'
target = pathlib.Path('C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/research/possible-bodies')
assert target.is_dir()
shutil.copy2(source/'randomness-staging.html',target/'randomness-staging.html')
(target/'randomness-staging').mkdir(exist_ok=True)
for image in (source/'randomness-staging').glob('*.png'):
    shutil.copy2(image,target/'randomness-staging'/image.name)
print('Published /research/possible-bodies/randomness-staging.html and its museum captures.')
