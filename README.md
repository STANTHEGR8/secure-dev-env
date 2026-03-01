# secure-dev-env

At first go into the `secure-dev-env` directory which will be located in Download folder.

Run the scripts given below to make all files executable:

```bash
find . -name "*.sh" -exec chmod +x {} +
```

```bash
sed -i ""s/\r$//" automation/install-all.sh
```
Now run the installation. Follow the steps given below:

```bash
cd automation
```

```bash
./install-all.sh
```
For further customization go the Customization directory and run the script of your choice.
Restart the pc to apply changes.
