# pissleakd

> wtf??? unrealircd6 s2s client in BASH!???

Yes.

pissleakd is a hopefully-not-terrible implementation of the UnrealIRCd 4+ protocol in pure* Bash.

The code is intended to be modular, and written *as if* made to be a full multiserver IRCd. In reality, of course, I have no fucking idea how to make one.
As for why it's **piss**leakd, check out [pissnet](https://wiki.letspiss.net).

<sup>\*Actually uses `openssl` and some \*nix-specific utils. I don't actually care if you consider this "pure".</sup>

## Configuring

On the linking server, add the following link block into your `unrealircd.conf` (replacing `pissleakd.baseduser.eu.org` with your own sname):
```
link pissleakd.baseduser.eu.org {
    incoming {
        mask { ip 11.22.33.44; } // change this! you don't want to be publicly linkable
    }
    password "foo"; // change this!
    class servers;
}
```

Then, configure pissleakd - all it needs is that link block's password, sname and sid.

Create a file called pass.txt and store the password inside.
In `pissleakd.sh`, change these:
```
sname="pissleakd.baseduser.eu.org"
sid="9RD"
```
to your new values (`sname` to your link block's name, `sid` to a proper UnrealIRCd SID).
