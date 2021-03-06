# Installation on raspberry pi

Assumes that the raspberry pi has the hostname `hamsterpi`

```bash
ssh -l pi hamsterpi.local
git clone https://github.com/viklund/hamster-code.git
cd hamster-code
sudo cp log-hamster-wheel.service /etc/systemd/system/
sudo systemctl enable log-hamster-wheel
sudo systemctl start log-hamster-wheel
```

# Copy logs from hamsterpi

```bash
rsync -rv pi@hamsterpi.local:hamster-code/logs .
```
