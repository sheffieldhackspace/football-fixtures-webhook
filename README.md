# Football Fixtures Webhook

Check football fixtures list for any fixtures in the near future.
If any are found, send a Discord webhook for each.

To start, generate a GitHub webhook and put it in the secrets file (`.env`)

```bash
cp .env
nano .env
```

## Usage

```bash
./check-and-send.sh
```

## Cron

```crontab
git clone 
0 4 * * * (cd /usr/alifeee/fixtures; ./check-and-send.sh >> cron.log 2>&1)
```
