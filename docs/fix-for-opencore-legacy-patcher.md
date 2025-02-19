# Fix for OpenCore Legacy Patcher

If you are using *OpenCore Legacy Patcher* it is possible that you are not being able to grant access permission to reminders and therefore you are facing a window saying *"Access to Reminders is not enabled for Reminders MenuBar"*.

<div>
  <img
    width="250"
    src="images/permission-not-enabled.png"
    alt="macOS window about access to Reminders not enabled for Reminders MenuBar"
  >
</div>

This issue is related to *OpenCore Legacy Patcher* as stated in the official documentation: [OpenCore Legacy Patcher | Unable to grant special permissions to apps](https://dortania.github.io/OpenCore-Legacy-Patcher/ACCEL.html#unable-to-grant-special-permissions-to-apps-ie-camera-access-to-zoom)

A workaround is to use TCCPlus to add this permission. I would suggest looking up some threads on the subject and if possible making a backup before trying commands that might affect the use of macOS.

I cannot guarantee that TCCPlus still works or if it's reliable for new versions of macOS. The workaround below was tested by other users on issue [#159](https://github.com/DamascenoRafael/reminders-menubar/issues/159), but if you decide to proceed it is at your own risk.

After downloading and extracting [TCCPlus](https://github.com/jslegendre/tccplus) in the *Downloads* folder, open the *Terminal* and run the following commands:

```shell
cd ~/Downloads/
chmod +x tccplus
./tccplus add Reminders br.com.damascenorafael.reminders-menubar
```
