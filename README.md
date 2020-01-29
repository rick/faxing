## send a fax, via phaxio.com

Send a file (e.g., a PDF file) to a recipient's fax number via the Phaxio.com API.

Get set up:

 - Go to https://www.phaxio.com/ and create an account
 - Put some money in there; I think it's costing $0.07 per page(?) these days
 - Grab your API keys from https://console.phaxio.com/api_credentials

Install:

```
$ bundle install
```

Set up your environment:

```
$ export PHAXIO_API_KEY=your-key-here
$ export PHAXIO_API_SECRET=your-secret-here
```

Run the faxing script:

```
# usage: bundle exec ruby script/fax.rb <phone-number> <file>
$ bundle exec ruby script/fax.rb 18885551212 ~/Desktop/impeach-trump-senator-dipshit.pdf
```

Check the progress on your dashboard at: https://console.phaxio.com/

![](images/fax-summary.png)

## send a latex-templated fax to a recipient defined in JSON

Lol.

But, seriously:

 - `brew install basictex`; you probably have to log out / in, or run `bash --login` to make this work after installation
   - yes, I'm presuming you're on a mac for this.  :shrug:
 - Copy data/me.json-sample over to data/me.json and put your (sender's) data in
 - Make data/whomever.json files for your recipients, and fill their data out. Add a "fax:" hash entry for a fax number
 - Tweak the templates/letter.tex template if you want to
 - Make a text file somewhere (like tmp/letter-body.txt) with the text of your letter body in it
 - Make sure your phaxio account and credentials are set up, like above
 - Run the script for a sender / recipient

```
$ ruby script/merge.rb 
Usage: script/merge.rb [options]
 (provide message body on STDIN)
    -v, --[no-]verbose               Run verbosely
        --from=SENDER                name of data/<sender>.json file to fetch sender data from (default: me)
        --to=RECIPIENT               name of data/<recipient>.json file to fetch recipient data from
        --template=TEMPLATE          name of templates/<template>.tex file to merge (default: letter)
$ cat tmp/letter.txt | ruby script/merge.rb --to=them


This is pdfTeX, Version 3.14159265-2.6-1.40.20 (TeX Live 2019) (preloaded format=pdflatex)
 restricted \write18 enabled.
entering extended mode
When ready, run:
bundle exec ruby script/fax.rb 2022283398 /Users/rick/git/faxing/tmp/output20200129-70151-11fy0ya.pdf

# probably a PDF viewer window with your PDF in it will show up; or an error message
```

If you're happy, run that command to send your fax.
