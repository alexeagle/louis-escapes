# Inside Playdate with C — Playdate SDK 3.0.6 (C API)

**Table of Contents**

## 1. About the C API

Playdate’s C API lets you use native C code in your game, using the same code to build both an OS specific library for the Simulator and a bin file for the Playdate hardware. Most games will use Playdate’s Lua API (documented in Inside Playdate with Lua). We include several example C programs in the SDK found at `C_API/Examples`. Read on to learn why and how to take advantage of the C API.

### 1.1. Why use the C API?

Performance. Lua is garbage collected. Its garbage collector’s performance varies wildly from game-to-game and even frame-to-frame within the same game. The collector’s performance is dependent on the amount of garbage generated per frame and, perhaps counterintuitively, the amount of persistent, non-garbage present in a frame (which it has to crawl to discover new garbage).

### 1.2. Before porting to C

Depending on how you’ve used Lua, porting part or all of your existing game from Lua to C can be quite involved. Make sure you’ve squeezed every last bit of performance out of Lua before refactoring or completely rewriting your game.

- flatten loops as much as possible
- localize frequently used global tables and functions, especially those used in loops
- disk access is slow on the hardware, preload any external assets like images, fonts, and sound effects
- pre-compute and cache the result of expensive computations
- pre-render and cache the result of expensive drawing routines
- pre-allocate and reuse tables
- move table allocations out of loops
- avoid excessive string concatenation with `..`, instead build a table of strings and use `table.concat()`

It’s worth mentioning that some of these suggestions are directly opposed with minimizing the amount of objects in active memory.

Also, be sure to profile on the hardware, the Playdate Simulator is often considerably faster than the hardware.

### 1.3. How to use the C API

There are two primary use cases for the C API:

1. extending the Lua runtime by adding native functions your Lua game can use (see playdate->lua->addFunction() and playdate->lua->registerClass())
2. bypassing the Lua runtime completely by replacing the Lua update callback with your own native function and building your entire game in C (see playdate->system->setUpdateCallback())

## 2. Prerequisites

To build games for the Playdate in C you will need to install: the Playdate SDK (See Inside Playdate for details), a platform native C compiler for the Simulator, and the ARM embedded compiler for the Playdate hardware. Native C compilers come with the standard development tools on the platform: Xcode, Visual Studio, and Linux development packages. The embedded ARM compiler will also need to be installed and varies based on platform.

1. MacOS: The Playdate SDK installer installs the ARM embedded compiler in `/usr/local/playdate` automatically.
2. Linux: Install the `arm-none-eabi-newlib` package (naming varies based on distro).
3. Windows: Install the Windows ARM embedded compiler `gcc-arm-none-eabi` from [developer.arm.com](https://developer.arm.com).

The SDK provides both CMake and Make configuration files for all the example C `C_API/Examples` projects. These are used to automatically configure the build enviornment when building Simulator and device versions of your game. We recommend using one of them as a starting point for your project; choosing the build configuration system you’re most familiar with. The Windows SDK only supports CMake.

> **NOTE:**

### 2.1. Set `PLAYDATE_SDK_PATH` Environment Variable

- On macOS, it is not required, but recommended
- On Linux, it is required for CMake and Make files
- On Windows, it is required for CMake (see the Building on Windows section for instructions on how to set it and skip this section)
  `edit ~/.zprofile`
  
  
  `edit ~/.bash_profile`

Add the following line — `export PLAYDATE_SDK_PATH=<path to SDK>` — replacing the placeholder text with your SDK location.

> **NOTE:**

> **TIP:**

## 3. IDEs

### 3.1. Xcode/CMake

To use Xcode to build the example C projects, you will first need to generate the Xcode project file from the CMake file. To do this, you’ll need CMake installed, we recommend installing it using [Brew](https://brew.sh). Once installed, open the Terminal and navigate into an example project and run the following commands:

```lua
mkdir build
cd build
cmake .. -G "Xcode"
```

This will create an Xcode project in the `build` directory. This Xcode project will produce a .pdx that’s ready to run and debug in the Simulator. When you want to build for the device, delete the contents of the `build` folder (or create a second folder), then run these commands which will build a device binary file and add it to the .pdx folder:

```lua
cd build
cmake -DCMAKE_TOOLCHAIN_FILE=<path to SDK>/C_API/buildsupport/arm.cmake ..
make
```

### 3.2. Xcode/Make

Using Xcode for Playdate development requires a few project settings in order to get in-Simulator debugging working.

1. Begin by making sure you have a working Makefile in your project root. The Makefile in the `Hello World` example project can serve as a starting template.
2. Create a new Xcode Project with a macos Library target and set it up as a plain C library. We recommend you add the word 'Simulator' to the target name
3. Add your source files to the target’s "Compile Sources" build phase
4. Add the full path to the `PlaydateSDK/C_API` folder to the _Header Search Paths_ build setting
5. Add `PLAYDATE_SIMULATOR=1` and `TARGET_EXTENSION=1` to the _Preprocessor Macros_ build setting
6. Add a new Run Script Phase in Build Phases called `Compile PDX` with the following in the body
7. Uncheck "Based on dependency analysis" in the Script Phase configuration

```lua
cp "${TARGET_BUILD_DIR}/${EXECUTABLE_NAME}" Source/pdex.dylib
make pdx
```

Assuming you don’t have any syntax errors in your code your game should now build successfully. Next we need to
hook up the Simulator to run your game in the Xcode debugger.

1. Edit the Scheme for your library target
2. In the Run configuration set the Executable to the Playdate Simulator
3. Switch to the _Arguments_ tab of the Run configuration and add the full path to the compiled .pdx bundle. It’s recommended that you put double-quotes around the path in case there are spaces in it.
4. Close the scheme and Run your game

In order to build for the device you’ll need to do the following:

1. Create a new _External Build System_ target with 'Device' in the name to differentiate it
2. Select the _Info_ section of the new target and set the Arguments to `device simulator`

Building the new Device target will add the cross-compiled binary to the .pdx bundle to run on the device.

### 3.3. CLion/CMake

CLion uses CMake files for most of it’s project configuration so project setup is straightforward

1. Add a `CMakeLists.txt` file to your project. The CMake file in the `Hello World` example project can serve as a starting template.
2. Open your project folder in CLion. It will detect the names of the Simulator and device targets automatically.
3. Open Preferences→Build→CMake and add a new build configuration with the following settings
  1. Name: `Device`
  2. Build Type: `Debug`
  3. CMake Options: `-DCMAKE_TOOLCHAIN_FILE=<path to SDK>/C_API/buildsupport/arm.cmake`

Once CLion reloads you’ll see that when you toggle between your Simulator and device target CLion select the appropriate build configuration. Next, you’ll need to tell CLion how to run the Simulator

1. Open the _Edit Configurations_ menu
2. Select your Simulator target and set the _Executable_ to the Playdate Simulator executable. The binary executable is at `SDK/bin/Playdate Simulator/Contents/Macos/Playdate Simulator`
3. Set the _Program arguments_ to the path of the compiled pdx bundle. Use `^-F` to access a file picker.

## 4. Command line

### 4.1. CMake

To build with CMake using Make on the command line run the following commands from the root of the project:

```lua
mkdir build
cd build
cmake ..
make
```

This will produce a .pdx that’s ready to run in the Simulator. When you want to build for the device, delete the contents of the `build` folder (or create a second folder), then run these commands which will build a device binary file and copy it to the .pdx:

```lua
cd build
cmake -DCMAKE_TOOLCHAIN_FILE=<path to SDK>/C_API/buildsupport/arm.cmake ..
make
```

### 4.2. Make

To build Playdate games using the example Makefiles you’ll need to install `arm-none-eabi-newlib` packages (naming may vary based on distro) as well as the usual C dev packages. Once these are installed, building is as simple as:

```lua
cd <project folder>
make
```

This will produce a .pdx that is ready to run on the device and the Simulator. Make options are:

builds the platform native library file and creates a .pdx that will run in the Simulator

builds the device binary file and creates .pdx that will run on the device

builds a .pdx suitable for both the Simulator and device

## 5. Building on Windows

### 5.1. Visual Studio/CMake

These instructions will show you how to build the example C projects included with the Playdate SDK which include CMakeLists. You can use our CMake files as a jumping off point for your own projects. Make is not supported in our example projects on Windows.

### 5.2. Install Development Tools

1. Install Visual Studio 2019 or 2022 with C tools
2. Install the GNU Arm Embedded Toolchain compiler `gcc-arm-none-eabi` from [developer.arm.com](https://developer.arm.com), when prompted add to Windows `PATH` environment variable
3. Install CMake for Windows from [cmake.org](https://cmake.org), when prompted add to Windows `PATH` environment variable. You may also use the CMake that is installed with Visual Studio.

### 5.3. Set `PLAYDATE_SDK_PATH` Environment Variable

The CMake build files find the Playdate SDK location by using an environment variable. To set it do the following:

1. From the Start Menu type `Environment Variables` and open the System Properties panel
2. Press the _Environment Variables…​_ button
3. Press _New…​_ and add `PLAYDATE_SDK_PATH` and select the location of your Playdate SDK directory

> **TIP:**

#### Building

The Simulator only supports 64 bit binary files. To ensure building 64 bit you’ll need to use the 64 bit Developer Command Prompt. To open this, select the Start Menu and find the application "x64 Native Tools Command Prompt for VS 2019". The name may vary based on which version of Visual Studio you have. It also can be opened from the Visual Studio Tools menu.

### 5.4. Building for the Simulator using Visual Studio

1. Navigate into the project directory and create a `build` folder, this is where CMake will generate its project files
2. Open a Visual Studio Developer Command Prompt from the Start Menu or from within Visual Studio
3. In the developer command prompt window, navigate into `build` directory and type `cmake ..`
4. Open the Visual Studio project generated in the `build` directory with the project name
5. In the Solutions Explorer within Visual Studio, select the target with the project name, not a meta target.
6. Right-click and select "Set as Startup Project"
7. Build and Run will create a .pdx file at the root level of the project directory and start a debugging session with the active .pdx by opening the Simulator.

### 5.5. Building for the Simulator using NMake

If you’d like to use VSCode or a different IDE you can also build using NMake.

1. Navigate into the project directory and create a `build` folder, this is where CMake will generate its project files
2. Open a Visual Studio Developer Command Prompt from the Start Menu or from within Visual Studio
3. In the developer command prompt window, navigate into build directory and type `cmake .. -G "NMake Makefiles"`
4. Type `nmake` to build the project. This will create a .pdx file at the root level of the project directory which can be run in the Simulator.

### 5.6. Building for the Playdate using NMake

Once you’ve debugged your game in the Simulator and would like to build it for the device, you’ll need to build it with the ARM tool chain.

1. Navigate into the project directory and create a `build` folder, this is where CMake will generate its project files
2. Open a Visual Studio Developer Command Prompt from the Start Menu or from within Visual Studio
3. In the developer command prompt window, navigate into build directory and type `cmake .. -G "NMake Makefiles" --toolchain=<path to SDK>/C_API/buildsupport/arm.cmake`
4. Type `nmake` to build the project. This will create a device binary file and copy it into the .pdx which can be run on the Playdate.

#### Building for Release

When you’re ready to do a release build, regenerate the build targets by passing `-DCMAKE_BUILD_TYPE=Release` argument to CMake.

> **NOTE:**

## 6. Game Initialization

When building for the device a `pdex.bin` file is created. The game launcher looks for this file in the compiled .pdx bundle and loads it into memory if it exists. (Because the Playdate OS doesn’t have a dynamic loader, the bin file is compiled for a specific location in memory; therefore, you can only have one bin/dylib per pdx bundle.).

> **NOTE:**

Your code should implement the function:

```
int eventHandler(PlaydateAPI* playdate, PDSystemEvent event, uint32_t arg);
```

```
typedef enum
{
	kEventInit,
	kEventInitLua,
	kEventLock,
	kEventUnlock,
	kEventPause,
	kEventResume,
	kEventTerminate,
	kEventKeyPressed,
	kEventKeyReleased,
	kEventLowPower,
	kEventMirrorStarted,
	kEventMirrorEnded
} PDSystemEvent;
```

When your `eventHandler` function is called, the _playdate_ argument will contain a pointer to the PlaydateAPI struct. The PlaydateAPI struct is your game’s interface back to the Playdate runtime, containing functions for accessing the sound system, display, filesystem, etc.

After loading `pdex.bin` into memory, the system calls your `eventHandler()` with _event_ set to `kEventInit`. If your game is implemented entirely in C code, you can supply your own run loop update function by calling playdate->system->setUpdateCallback() here.

If you don’t provide an update callback, the system initializes a Lua context and calls `eventHandler()` again with _event_ equal to `kEventInitLua`. At this point, you can use playdate->lua->addFunction() and playdate->lua->registerClass() to extend the Lua runtime. Note that this happens before main.lua is loaded and run.

When an arbitrary key is pressed or released in the Simulator this function is called with _event_ set to `kEventKeyPressed` or `kEventKeyReleased` and the keycode of the key in the _arg_ argument.

Finally, this function can also handle lifetime events like device lock and unlock, as well as game pause, resume, terminate, and low-power sleep, and connecting to and disconnecting from Mirror.

## 7. API reference

### 7.1. Utility functions

#### Memory allocation

#### `void* playdate->system->realloc(void* ptr, size_t size)`
*function*

Allocates heap space if _ptr_ is NULL, else reallocates the given pointer. If _size_ is zero, frees the given pointer.

#### `struct PDInfo* playdate->system->getSystemInfo(void)`
*function*

Returns a pointer to a struct containing info about the system.

```
struct PDInfo
{
	uint32_t osversion;
	PDLanguage language;
}
```

#### Logging

#### `void playdate->system->error(const char* format, ...)`
*function*

Calls the log function, outputting an error in red to the console, then pauses execution.

#### `void playdate->system->logToConsole(const char* format, ...)`
*function*

Calls the log function.

Equivalent to `print()` in the Lua API.

#### Interacting with the System Menu

Your game can add up to three menu items to the system menu. Three types of menu items are supported: normal action menu items, checkmark menu items, and options menu items.

```lua
PDMenuItem *menuItem = pd->system->addMenuItem("Item 1", menuItemCallback, NULL);
PDMenuItem *checkMenuItem = pd->system->addCheckmarkMenuItem("Item 2", 1, menuCheckmarkCallback, NULL);
const char *options[] = {"one", "two", "three"};
PDMenuItem *optionMenuItem = pd->system->addOptionsMenuItem("Item 3", options, 3, menuOptionsCallback, NULL);
```

```
typedef void PDMenuItemCallbackFunction(void* userdata);
```

#### `PDMenuItem* playdate->system->addMenuItem(const char* title, PDMenuItemCallbackFunction* callback, void* userdata)`
*function*

_title_ will be the title displayed by the menu item.

Adds a new menu item to the System Menu. When invoked by the user, this menu item will:

1. Invoke your _callback_ function.
2. Hide the System Menu.
3. Unpause your game and call eventHandler() with the kEventResume _event_.

Your game can then present an options interface to the player, or take other action, in whatever manner you choose.

The returned menu item is freed when removed from the menu; it does not need to be freed manually.

#### `PDMenuItem* playdate->system->addCheckmarkMenuItem(const char* title, int value, PDMenuItemCallbackFunction* callback, void* userdata)`
*function*

Adds a new menu item that can be checked or unchecked by the player.

_title_ will be the title displayed by the menu item.

_value_ should be 0 for unchecked, 1 for checked.

If this menu item is interacted with while the system menu is open, _callback_ will be called when the menu is closed.

The returned menu item is freed when removed from the menu; it does not need to be freed manually.

#### `PDMenuItem* playdate->system->addOptionsMenuItem(const char* title, const char** options, int optionsCount, PDMenuItemCallbackFunction* callback, void* userdata)`
*function*

Adds a new menu item that allows the player to cycle through a set of options.

_title_ will be the title displayed by the menu item.

_options_ should be an array of strings representing the states this menu item can cycle through. Due to limited horizontal space, the option strings and title should be kept short for this type of menu item.

_optionsCount_ should be the number of items contained in _options_.

If this menu item is interacted with while the system menu is open, _callback_ will be called when the menu is closed.

The returned menu item is freed when removed from the menu; it does not need to be freed manually.

#### `void playdate->system->removeMenuItem(PDMenuItem *menuItem)`
*function*

Removes the menu item from the system menu.

#### `void playdate->system->removeAllMenuItems()`
*function*

Removes all custom menu items from the system menu.

#### `const char* playdate->system->getMenuItemTitle(PDMenuItem *menuItem)`
*function*

#### `void playdate->system->setMenuItemTitle(PDMenuItem *menuItem, const char* title)`
*function*

Gets or sets the display title of the menu item.

#### `int playdate->system->getMenuItemValue(PDMenuItem *menuItem)`
*function*

#### `void playdate->system->setMenuItemValue(PDMenuItem *menuItem, int value)`
*function*

Gets or sets the integer value of the menu item.

For checkmark menu items, 1 means checked, 0 unchecked. For option menu items, the value indicates the array index of the currently selected option.

#### `void* playdate->system->getMenuItemUserdata(PDMenuItem *menuItem)`
*function*

#### `void playdate->system->setMenuItemUserdata(PDMenuItem *menuItem, void* userdata)`
*function*

Gets or sets the userdata value associated with this menu item.

#### Time and Date

#### `unsigned int playdate->system->getCurrentTimeMilliseconds(void)`
*function*

Returns the number of milliseconds since…​some arbitrary point in time. This should present a consistent timebase while a game is running, but the counter will be disabled when the device is sleeping.

#### `unsigned int playdate->system->getSecondsSinceEpoch(unsigned int *milliseconds)`
*function*

Returns the number of seconds (and sets _milliseconds_ if not NULL) elapsed since midnight (hour 0), January 1, 2000.

#### `void playdate->system->resetElapsedTime(void)`
*function*

Resets the high-resolution timer.

#### `float playdate->system->getElapsedTime()`
*function*

Returns the number of seconds since `playdate.resetElapsedTime()` was called. The value is a floating-point number with microsecond accuracy.

#### `float playdate->system->delay(uint32_t milliseconds)`
*function*

Pauses execution for the given number of milliseconds.

#### `int32_t playdate->system->getTimezoneOffset()`
*function*

Returns the system timezone offset from GMT, in seconds.

```
struct PDDateTime
{
	uint16_t year;
	uint8_t month; // 1-12
	uint8_t day; // 1-31
	uint8_t weekday; // 1=monday-7=sunday
	uint8_t hour;
	uint8_t minute;
	uint8_t second;
};
```

#### `void playdate->system->convertEpochToDateTime(uint32_t epoch, struct PDDateTime* datetime)`
*function*

Converts the given epoch time to a PDDateTime.

#### `uint32_t playdate->system->convertDateTimeToEpoch(struct PDDateTime* datetime)`
*function*

Converts the given PDDateTime to an epoch time.

#### `void playdate->system->getServerTime(void (*callback)(const char* time, const char* err))`
*function*

Queries the Playdate server for the current time, in seconds elapsed since midnight (hour 0), January 1 2000 UTC. This provides games with a reliable clock source, since the internal clock can be set by the user. The function is asynchronous, returning the server time to a callback function passed in. If an error occurred fetching the time, the `error` argument is set instead.

#### `int playdate->system->shouldDisplay24HourTime()`
*function*

Returns 1 if the user has set the 24-Hour Time preference in the Settings program.

#### Miscellaneous

#### `int playdate->system->getFlipped()`
*function*

Returns 1 if the global "flipped" system setting is set, otherwise 0.

#### `int playdate->system->getReduceFlashing()`
*function*

Returns 1 if the global "reduce flashing" system setting is set, otherwise 0.

#### `int playdate->system->formatString(char **outstring, const char *format, ...)`
*function*

Creates a formatted string and returns it via the _outstring_ argument. The arguments and return value match libc’s `asprintf()`: the format string is standard `printf()` style, the string returned in _outstring_ should be freed by the caller when it’s no longer in use, and the return value is the length of the formatted string.

#### `int playdate->system->vaFormatString(char **ret, const char *format, va_list args)`
*function*

Allocates and formats a string using a variadic `va_list` argument, in the style of `vasprintf()`. The string returned via _ret_ should be freed by the caller when it is no longer in use. The return value from the function is the length of the formatted string.

#### `int playdate->system->parseString(const char *str, const char *format, ...)`
*function*

Like libc `sscanf()`, parses a string according to a format string and places the values into pointers passed in after the format. The return value is the number of items matched.

#### `void playdate->system->setMenuImage(LCDBitmap* bitmap, int xOffset);`
*function*

A game can optionally provide an image to be displayed alongside the system menu. _bitmap_ must be a 400x240 LCDBitmap. All important content should be in the left half of the image in an area 200 pixels wide, as the menu will obscure the rest. The right side of the image will be visible briefly as the menu animates in and out.

Optionally, a non-zero _xoffset_, can be provided. This must be a number between 0 and 200 and will cause the menu image to animate to a position offset left by xoffset pixels as the menu is animated in.

This function could be called in response to the kEventPause _event_ in your implementation of eventHandler().

#### `void playdate->system->setUpdateCallback(PDCallbackFunction* update, void* userdata)`
*function*

```
int PDCallbackFunction(void* userdata);
```

Replaces the default Lua run loop function with a custom update function. The update function should return a non-zero number to tell the system to update the display, or zero if update isn’t needed.

#### `void playdate->system->restart(const char* args)`
*function*

Reinitializes the Playdate runtime and restarts the currently running game. The `args` string is available after restart via `getLaunchArgs()`:

#### `const char* playdate->system->getLaunchArgs(const char** outpath)`
*function*

Returns the string passed in as an argument at launch time, either via the command line when launching the simulator, the device console `run` command, or the above `restart()` function. If `outpath` is not NULL, the path of the currently loaded game is returned in it.

#### `void playdate->system->setSerialMessageCallback(void (*callback)(const char* data));`
*function*

Provides a callback to receive messages sent to the device over the serial port using the `msg` command. If no device is connected, you can send these messages to a game in the simulator by entering `!msg <message>` in the Lua console.

#### `void playdate->system->drawFPS(int x, int y)`
*function*

Calculates the current frames per second and draws that value at _x, y_.

#### `float playdate->system->getBatteryPercentage()`
*function*

Returns a value from 0-100 denoting the current level of battery charge. 0 = empty; 100 = full.

#### `float playdate->system->getBatteryVoltage()`
*function*

Returns the battery’s current voltage level.

#### `float playdate->system->clearICache()`
*function*

Flush the CPU instruction cache, on the very unlikely chance you’re modifying instruction code on the fly. (If you don’t know what I’m talking about, you don’t need this. :smile:)

### 7.2. Audio

#### `uint32_t playdate->sound->getCurrentTime(void)`
*function*

Returns the sound engine’s current time value, in units of sample frames, 44,100 per second.

Equivalent to `playdate.sound.getCurrentTime()` in the Lua API.

#### `SoundChannel* playdate->sound->getDefaultChannel(void)`
*function*

Returns the default channel, where sound sources play if they haven’t been explicity assigned to a different channel.

#### `int playdate->sound->addChannel(SoundChannel* channel)`
*function*

Adds the given channel to the sound engine. Returns 1 if the channel was added, 0 if it was already in the engine.

#### `SoundSource* playdate->sound->addSource(AudioSourceFunction* callback, void* context, int stereo)`
*function*

The _callback_ function you pass in will be called every audio render cycle.

```
int AudioSourceFunction(void* context, int16_t* left, int16_t* right, int len)
```

This function should fill the passed-in _left_ buffer (and _right_ if it’s a stereo source) with _len_ samples each and return 1, or return 0 if the source is silent through the cycle.

#### `int playdate->sound->removeSource(SoundSource* source)`
*function*

Removes the given SoundSource object from its channel, whether it’s in the default channel or a channel created with playdate→sound→addChannel(). Returns 1 if a source was removed, 0 if the source wasn’t in a channel.

#### `int playdate->sound->removeChannel(SoundChannel* channel)`
*function*

Removes the given channel from the sound engine. Returns 1 if the channel was successfully removed, 0 if the channel is the default channel or hadn’t been previously added.

#### `int playdate->sound->setMicCallback(AudioInputFunction* callback, void* context, enum MicSource source)`
*function*

The _callback_ you pass in will be called every audio cycle.

```
int AudioInputFunction(void* context, int16_t* data, int len)
```

```
enum MicSource {
	kMicInputAutodetect = 0,
	kMicInputInternal = 1,
	kMicInputHeadset = 2
};
```

Your input callback will be called with the recorded audio data, a monophonic stream of samples. The function should return 1 to continue recording, 0 to stop recording.

The Playdate hardware has a circuit that attempts to autodetect the presence of a headset mic, but there are cases where you may want to override this. For instance, if you’re using a headphone splitter to wire an external source to the mic input, the detector may not always see the input. Setting the source to `kMicInputHeadset` forces recording from the headset. Using `kMicInputInternal` records from the device mic even when a headset with a mic is plugged in. And `kMicInputAutodetect` uses a headset mic if one is detected, otherwise the device microphone. `setMicCallback()` returns which source the function used, internal or headset, or 0 on error.

#### `void playdate->sound->getHeadphoneState(int* headphone, int* mic, void (*changeCallback)(int headphone, int mic))`
*function*

If _headphone_ contains a pointer to an int, the value is set to 1 if headphones are currently plugged in. Likewise, _mic_ is set if the headphones include a microphone. If _changeCallback_ is provided, it will be called when the headset or mic status changes, and audio output will **not** automatically switch from speaker to headphones when headphones are plugged in (and vice versa). In this case, the callback should use `playdate→sound→setOutputsActive()` to change the output if needed.

Equivalent to `playdate.sound.getHeadphoneState()` in the Lua API.

#### `void playdate->sound->setOutputsActive(int headphone, int speaker)`
*function*

Force audio output to the given outputs, regardless of headphone status.

Equivalent to `playdate.sound.setOutputsActive()` in the Lua API.

#### Channels

#### `SoundChannel* playdate->sound->channel->newChannel(void)`
*function*

Returns a new _SoundChannel_ object.

#### `void playdate->sound->channel->freeChannel(SoundChannel* channel)`
*function*

Frees the given _SoundChannel_.

#### `void playdate->sound->channel->addSource(SoundChannel* channel, SoundSource* source)`
*function*

Adds a SoundSource to the channel. If a source is not assigned to a channel, it plays on the default global channel.

#### `int playdate->sound->channel->removeSource(SoundChannel* channel, SoundSource* source)`
*function*

Removes a SoundSource to the channel. Returns 1 if the source was found in (and removed from) the channel, otherwise 0.

#### `int playdate->sound->channel->addEffect(SoundChannel* channel, SoundEffect* effect)`
*function*

Adds a SoundEffect to the channel. Returns 1 if successful, 0 if the effect is already in use.

#### `int playdate->sound->channel->removeEffect(SoundChannel* channel, SoundEffect* effect)`
*function*

Removes a SoundEffect from the channel. Returns 1 if the effect was in the channel and removed, otherwise 0.

#### `void playdate->sound->channel->setVolume(SoundChannel* channel, float volume)`
*function*

Sets the volume for the channel, in the range [0-1].

#### `float playdate->sound->channel->getVolume(SoundChannel* channel)`
*function*

Gets the volume for the channel, in the range [0-1].

#### `void playdate->sound->channel->setVolumeModulator(SoundChannel* channel, PDSynthSignalValue* mod)`
*function*

Sets a signal to modulate the channel volume. Set to _NULL_ to clear the modulator.

#### `PDSynthSignalValue* playdate->sound->channel->getVolumeModulator(SoundChannel* channel)`
*function*

Gets a signal modulating the channel volume.

#### `void playdate->sound->channel->setPan(SoundChannel* channel, float pan)`
*function*

Sets the pan parameter for the channel. Valid values are in the range [-1,1], where -1 is left, 0 is center, and 1 is right.

#### `void playdate->sound->channel->setPanModulator(SoundChannel* channel, PDSynthSignalValue* mod)`
*function*

Sets a signal to modulate the channel pan. Set to _NULL_ to clear the modulator.

#### `PDSynthSignalValue* playdate->sound->channel->getPanModulator(SoundChannel* channel)`
*function*

Gets a signal modulating the channel pan.

#### `SoundSource* playdate->sound->channel->addCallbackSource(SoundChannel* channel, AudioSourceFunction* callback, void* context, int stereo)`
*function*

Creates a new SoundSource using the given data provider callback and adds it to the channel.

```
int AudioSourceFunction(void* context, int16_t* left, int16_t* right, int len)
```

This function should fill the passed-in _left_ buffer (and _right_ if it’s a stereo source) with _len_ samples each and return 1, or return 0 if the source is silent through the cycle. The caller takes ownership of the allocated SoundSource, and should free it with

```
playdate->system->realloc(source, 0);
```

when it is not longer in use.

#### `PDSynthSignalValue* playdate->sound->channel->getDryLevelSignal(SoundChannel* channel)`
*function*

Returns a signal that follows the volume of the channel before effects are applied.

#### `PDSynthSignalValue* playdate->sound->channel->getWetLevelSignal(SoundChannel* channel)`
*function*

Returns a signal that follows the volume of the channel after effects are applied.

#### SoundSource

SoundSource is the parent class of FilePlayer, SamplePlayer, PDSynth, DelayLineTap, and PDSynthInstrument. Any objects of those types can be cast to SoundSource type and used in these functions.

#### `void playdate->sound->source->setVolume(SoundSource* c, float lvol, float rvol)`
*function*

Sets the playback volume (0.0 - 1.0) for left and right channels of the source.

#### `void playdate->sound->source->getVolume(SoundSource* c, float* outlvol, float* outrvol)`
*function*

Gets the playback volume (0.0 - 1.0) for left and right channels of the source.

#### `int playdate->sound->source->isPlaying(SoundSource* c)`
*function*

Returns 1 if the source is currently playing.

#### `void playdate->sound->source->setCompletionCallback(SoundSource* c, sndCallbackProc callback, void* userdata)`
*function*

```
int sndCallbackProc(SoundSource* c, void* userdata);
```

Sets a function to be called when the source has finished playing.

#### AudioSample

#### `AudioSample* playdate->sound->sample->newSampleBuffer(int length)`
*function*

Allocates and returns a new AudioSample with a buffer large enough to load a file of _length_ bytes.

#### `void playdate->sound->sample->loadIntoSample(AudioSample* sample, const char* path)`
*function*

Loads the sound data from the file at _path_ into an existing AudioSample, _sample_.

#### `AudioSample* playdate->sound->sample->load(const char* path)`
*function*

Allocates and returns a new AudioSample, with the sound data loaded in memory. If there is no file at _path_, the function returns null.

#### `int playdate->sound->sample->decompress(void)`
*function*

If the sample is ADPCM compressed, decompresses the sample data to 16-bit PCM data. This increases the sample’s memory footprint by 4x and does not affect the quality in any way, but it is necessary if you want to use the sample in a synth or play the file backwards. Returns 1 if successful, 0 if there’s not enough memory for the uncompressed data.

#### `AudioSample* playdate->sound->sample->newSampleFromData(uint8_t* data, SoundFormat format, uint32_t sampleRate, int byteCount, int shouldFreeData)`
*function*

Returns a new AudioSample referencing the given audio data. If _shouldFreeData_ is set, _data_ is freed when the sample object is freed. The sample keeps a pointer to the data instead of copying it, so the data must remain valid while the sample is active. _format_ is one of the following values:

```
typedef enum
{
	kSound8bitMono = 0,
	kSound8bitStereo = 1,
	kSound16bitMono = 2,
	kSound16bitStereo = 3,
	kSoundADPCMMono = 4,
	kSoundADPCMStereo = 5
} SoundFormat;
```

`pd_api_sound.h` also provides some helper macros and functions:

```lua
#define SoundFormatIsStereo(f) ((f)&1)
#define SoundFormatIs16bit(f) ((f)>=kSound16bitMono)
static inline uint32_t SoundFormat_bytesPerFrame(SoundFormat fmt);
```

#### `void playdate->sound->sample->getData(AudioSample* sample, uint8_t** data, SoundFormat* format, uint32_t* sampleRate, uint32_t* bytelength)`
*method*

Retrieves the sample’s data, format, sample rate, and data length.

#### `void playdate->sound->sample->freeSample(AudioSample* sample)`
*function*

Frees the given _sample_. If the sample was created with playdate→sound→sample→newSampleFromData() and the _shouldFreeData_ flag was set, the sample’s source data is also freed.

#### `float playdate->sound->sample->getLength(AudioSample* sample)`
*function*

Returns the length, in seconds, of _sample_.

#### FilePlayer

#### `FilePlayer* playdate->sound->fileplayer->newPlayer(void);`
*function*

Allocates a new FilePlayer.

#### `void playdate->sound->fileplayer->freePlayer(FilePlayer* player);`
*function*

Frees the given _player_.

#### `int playdate->sound->fileplayer->loadIntoPlayer(FilePlayer* player, const char* path);`
*function*

Prepares _player_ to stream the file at _path_. Returns 1 if the file exists, otherwise 0.

#### `void playdate->sound->fileplayer->pause(FilePlayer* player);`
*function*

Pauses the file _player_.

#### `int playdate->sound->fileplayer->play(FilePlayer* player, int repeat);`
*function*

Starts playing the file _player_. If _repeat_ is greater than one, it loops the given number of times. If zero, it loops endlessly until it is stopped with playdate->sound->fileplayer->stop(). Returns 1 on success, 0 if buffer allocation failed.

#### `int playdate->sound->fileplayer->isPlaying(FilePlayer* player);`
*function*

Returns one if _player_ is playing, zero if not.

#### `void playdate->sound->fileplayer->setBufferLength(FilePlayer* player, float bufferLen);`
*function*

Sets the buffer length of _player_ to _bufferLen_ seconds;

#### `float playdate->sound->fileplayer->getLength(FilePlayer* player);`
*function*

Returns the length, in seconds, of the file loaded into _player_.

#### `void playdate->sound->fileplayer->setFinishCallback(FilePlayer* player, sndCallbackProc callback, void* userdata);`
*function*

Sets a function to be called when playback has completed. This is an alias for playdate→sound→source→setFinishCallback().

```
typedef void sndCallbackProc(SoundSource* c, void* userdata);
```

#### `int playdate->sound->fileplayer->didUnderrun(FilePlayer* player);`
*function*

Returns one if _player_ has underrun, zero if not.

#### `void playdate->sound->fileplayer->setLoopRange(FilePlayer* player, float start, float end);`
*function*

Sets the _start_ and _end_ of the loop region for playback, in seconds. If _end_ is omitted, the end of the file is used.

#### `void playdate->sound->fileplayer->setOffset(FilePlayer* player, float offset);`
*function*

Sets the current _offset_ in seconds.

#### `float playdate->sound->fileplayer->getOffset(FilePlayer* player);`
*function*

Returns the current offset in seconds for _player_.

#### `void playdate->sound->fileplayer->setRate(FilePlayer* player, float rate)`
*function*

Sets the playback _rate_ for the _player_. 1.0 is normal speed, 0.5 is down an octave, 2.0 is up an octave, etc. Unlike sampleplayers, fileplayers can’t play in reverse (i.e., rate < 0).

#### `float playdate->sound->fileplayer->getRate(FilePlayer* player)`
*function*

Returns the playback rate for _player_.

#### `void playdate->sound->fileplayer->setStopOnUnderrun(FilePlayer* player, int flag)`
*function*

By default, if the fileplayer runs out of data it does not stop playback but instead restarts (after an audible stutter) as soon as data becomes available. Setting the flag to _true_ changes this behavior so that it stops playback and calls the fileplayer’s finish callback, if set.

#### `void playdate->sound->fileplayer->setVolume(FilePlayer* player, float left, float right);`
*function*

Sets the playback volume for left and right channels of _player_.

#### `void playdate->sound->fileplayer->getVolume(FilePlayer* player, float* outleft, float* outright);`
*function*

Gets the left and right channel playback volume for _player_.

#### `void playdate->sound->fileplayer->stop(FilePlayer* player);`
*function*

Stops playing the file.

#### `void playdate->sound->fileplayer->fadeVolume(FilePlayer* player, float left, float right, int32_t len, sndCallbackProc finishCallback, void* userdata);`
*function*

Changes the volume of the fileplayer to _left_ and _right_ over a length of _len_ sample frames, then calls the provided callback (if set).

#### SamplePlayer

#### `float playdate->sound->sampleplayer->getLength(SamplePlayer* player)`
*function*

Returns the length, in seconds, of the sample assigned to _player_.

#### `int playdate->sound->sampleplayer->isPlaying(SamplePlayer* player)`
*function*

Returns one if _player_ is playing a sample, zero if not.

#### `SamplePlayer* playdate->sound->sampleplayer->newPlayer(void)`
*function*

Allocates and returns a new SamplePlayer.

#### `int playdate->sound->sampleplayer->play(SamplePlayer* player, int repeat, float rate)`
*function*

Starts playing the sample in _player_.

If _repeat_ is greater than one, it loops the given number of times. If zero, it loops endlessly until it is stopped with playdate->sound->sampleplayer->stop(). If negative one, it does ping-pong looping.

_rate_ is the playback rate for the sample; 1.0 is normal speed, 0.5 is down an octave, 2.0 is up an octave, etc.

Returns 1 on success (which is always, currently).

#### `void playdate->sound->sampleplayer->setFinishCallback(SamplePlayer* player, sndCallbackProc callback, void* userdata)`
*function*

Sets a function to be called when playback has completed. See sndCallbackProc.

#### `void playdate->sound->sampleplayer->setOffset(SamplePlayer* player, float offset)`
*function*

Sets the current _offset_ of the SamplePlayer, in seconds.

#### `float playdate->sound->sampleplayer->getOffset(SamplePlayer* player);`
*function*

Returns the current offset in seconds for _player_.

#### `void playdate->sound->sampleplayer->setPlayRange(SamplePlayer* player, int start, int end)`
*function*

When used with a repeat of -1, does ping-pong looping, with a _start_ and _end_ position in frames.

#### `void playdate->sound->sampleplayer->setPaused(SamplePlayer* player, int paused)`
*function*

Pauses or resumes playback.

#### `void playdate->sound->sampleplayer->setRate(SamplePlayer* player, float rate)`
*function*

Sets the playback _rate_ for the _player_. 1.0 is normal speed, 0.5 is down an octave, 2.0 is up an octave, etc. A negative rate produces backwards playback for PCM files, but does not work for ADPCM-encoded files.

#### `float playdate->sound->sampleplayer->getRate(SamplePlayer* player)`
*function*

Returns the playback rate for _player_.

#### `void playdate->sound->sampleplayer->setSample(SamplePlayer* player, AudioSample* sample)`
*function*

Assigns _sample_ to _player_.

#### `void playdate->sound->sampleplayer->setVolume(SamplePlayer* player, float left, float right)`
*function*

Sets the playback volume for left and right channels.

#### `void playdate->sound->sampleplayer->getVolume(SamplePlayer* player, float* outleft, float* outright)`
*function*

Gets the current left and right channel volume of the sampleplayer.

#### `void playdate->sound->sampleplayer->stop(SamplePlayer* player)`
*function*

Stops playing the sample.

#### `void playdate->sound->sampleplayer->freePlayer(SamplePlayer* player)`
*function*

Frees the given _player_.

#### PDSynth

#### `PDSynth* playdate->sound->synth->newSynth(void)`
*function*

Creates a new synth object.

#### `void playdate->sound->synth->freeSynth(PDSynth* synth)`
*function*

Frees a synth object, first removing it from the sound engine if needed.

#### `PDSynth* playdate->sound->synth->copy(PDSynth* synth)`
*function*

Returns a copy of the given synth. Caller assumes ownership of the returned object and should free it when it is no longer in use.

#### `void playdate->sound->synth->setWaveform(PDSynth* synth, SoundWaveform wave)`
*function*

Sets the waveform of the synth. The SoundWaveform enum contains the following values:

```
typedef enum
{
	kWaveformSquare,
	kWaveformTriangle,
	kWaveformSine,
	kWaveformNoise,
	kWaveformSawtooth,
	kWaveformPOPhase,
	kWaveformPODigital,
	kWaveformPOVosim
} SoundWaveform;
```

#### `void playdate->sound->synth->setGenerator(PDSynth* synth, int stereo, synthRenderFunc* render, synthNoteOnFunc* noteOn, synthReleaseFunc* release, synthSetParameterFunc* setparam, synthDeallocFunc* dealloc, synthCopyUserdataFunc copyUserdata, void* userdata)`
*function*

```
typedef int (*synthRenderFunc)(void* userdata, int32_t* left, int32_t* right, int nsamples, uint32_t rate, int32_t drate);
typedef void (*synthNoteOnFunc)(void* userdata, MIDINote note, float velocity, float len); // len == -1 if indefinite
typedef void (*synthReleaseFunc)(void* userdata, int endoffset);
typedef int (*synthSetParameterFunc)(void* userdata, int parameter, float value);
typedef void (*synthDeallocFunc)(void* userdata);
typedef void* (*synthCopyUserdata)(void* userdata);
```

Provides custom waveform generator functions for the synth. These functions are called on the audio render thread, so they should return as quickly as possible. _synthRenderFunc_, the data provider callback, is the only required function.

_synthRenderFunc_: called every audio cycle to get the samples for playback. _left_ (and _right_ if _setGenerator()_ was called with the stereo flag set) are sample buffers in Q8.24 format. _rate_ is the amount to change a (Q32) phase accumulator each sample, and _drate_ is the amount to change _rate_ each sample. Custom synths can ignore this and use the _note_ paramter in the noteOn function to handle pitch, but synth→setFrequencyModulator() won’t work as expected.

_synthNoteOnFunc_: called when the synth receives a note on event. _len_ is the length of the note in seconds, or -1 if it’s not known yet when the note will end.

_synthReleaseFunc_: called when the synth receives a note off event. _endoffset_ is how many samples into the current render cycle the note ends, allowing for sample-accurate timing.

_synthSetParameterFunc_: called when a parameter change is received from synth→setParameter() or a modulator.

_synthDeallocFunc_: called when the synth is being dealloced. This function should free anything that was allocated for the synth and also free the _userdata_ itself.

_synthCopyUserdata_: called when synth→copy() needs a unique copy of the synth’s userdata. External objects should be retained or copied so that the object isn’t freed while the synth is still using it.

#### `void playdate->sound->synth->setSample(PDSynth* synth, AudioSample* sample, uint32_t sustainStart, uint32_t sustainEnd)`
*function*

Provides a sample for the synth to play. Sample data must be uncompressed PCM, not ADPCM. If a sustain range is set, it is looped while the synth is playing a note. When the note ends, if an envelope has been set on the synth and the sustain range goes to the end of the sample (i.e. there’s no release section of the sample after the sustain range) then the sustain section continues looping during the envelope release; otherwise it plays through the end of the sample and stops. As a convenience, if `sustainEnd` is zero and `sustainStart` is greater than zero, `sustainEnd` will be set to the length of the sample.

#### `int playdate->sound->synth->setWavetable(PDSynth* synth, AudioSample* sample, int log2size, int columns, rows)`
*function*

Sets a wavetable for the synth to play. Sample data must be 16-bit mono uncompressed. `log2size` is the base 2 logarithm of the number of samples in each waveform "cell" in the table, and `columns` and `rows` gives the number of cells in each direction; for example, if the wavetable is arranged in an 8x8 grid, `columns` and `rows` are both 8 and `log2size` is 6, since 2^6 = 8x8.

The function returns 1 on success. If it fails, use playdate→sound→getError() to get a human-readable error message.

The synth’s "position" in the wavetable is set manually with setParameter() or automated with setParameterModulator(). In some cases it’s easier to use a parameter that matches the waveform position in the table, in others (notably when using envelopes and lfos) it’s more convenient to use a 0-1 scale, so there’s some redundancy here. Parameters are

- 1: x position, values are from 0 to the table width
- 2: x position, values are from 0 to 1, parameter is scaled up to table width

For 2-D tables (`height` > 1):

- 3: y position, values are from 0 to the table height
- 4: y position, values are from 0 to 1, parameter is scaled up to table height

#### `void playdate->sound->synth->setAttackTime(PDSynth* synth, float attack)`
*function*

#### `void playdate->sound->synth->setDecayTime(PDSynth* synth, float decay)`
*function*

#### `void playdate->sound->synth->setSustainLevel(PDSynth* synth, float sustain)`
*function*

#### `void playdate->sound->synth->setReleaseTime(PDSynth* synth, float release)`
*function*

Sets the parameters of the synth’s ADSR envelope.

#### `void playdate->sound->synth->clearEnvelope(PDSynth* synth)`
*function*

Clears the synth’s envelope settings.

#### `PDSynthEnvelope* playdate->sound->synth->getEnvelope(PDSynth* synth)`
*function*

Returns the synth’s envelope. The PDSynth object owns this envelope, so it must not be freed.

#### `void playdate->sound->synth->setTranspose(PDSynth* synth, float halfSteps)`
*function*

Transposes the synth’s output by the given number of half steps. For example, if the transpose is set to 2 and a C note is played, the synth will output a D instead.

#### `void playdate->sound->synth->setFrequencyModulator(PDSynth* synth, PDSynthSignalValue* mod)`
*function*

Sets a signal to modulate the synth’s frequency. The signal is scaled so that a value of 1 doubles the synth pitch (i.e. an octave up) and -1 halves it (an octave down). Set to _NULL_ to clear the modulator.

#### `PDSynthSignalValue* playdate->sound->synth->getFrequencyModulator(PDSynth* synth)`
*function*

Returns the currently set frequency modulator.

#### `void playdate->sound->synth->setAmplitudeModulator(PDSynth* synth, PDSynthSignalValue* mod)`
*function*

Sets a signal to modulate the synth’s output amplitude. Set to _NULL_ to clear the modulator.

#### `PDSynthSignalValue* playdate->sound->synth->getAmplitudeModulator(PDSynth* synth)`
*function*

Returns the currently set amplitude modulator.

#### `void playdate->sound->synth->playNote(PDSynth* synth, float freq, float vel, float len, uint32_t when)`
*function*

Plays a note on the synth, at the given frequency. Specify _len_ = -1 to leave the note playing until a subsequent noteOff() call. If _when_ is 0, the note is played immediately, otherwise the note is scheduled for the given time. Use playdate→sound→getCurrentTime() to get the current time.

#### `void playdate->sound->synth->playMIDINote(PDSynth* synth, MIDINote note, float vel, float len, uint32_t when)`
*function*

The same as playNote but uses MIDI note (where 60 = C4) instead of frequency. Note that `MIDINote` is a typedef for `float', meaning fractional values are allowed (for all you microtuning enthusiasts).

#### `void playdate->sound->synth->noteOff(PDSynth* synth, uint32_t when)`
*function*

Sends a note off event to the synth, either immediately (_when_ = 0) or at the scheduled time.

#### `void playdate->sound->synth->setVolume(PDSynth* synth, float lvol, float rvol)`
*function*

Sets the playback volume (0.0 - 1.0) for the left and, if the synth is stereo, right channels of the synth. This is equivalent to

```
playdate->sound->source->setVolume((SoundSource*)synth, lvol, rvol);
```

#### `float playdate->sound->synth->getVolume(PDSynth* synth, float* outlvol, float* outrvol)`
*function*

Gets the playback volume for the left and right (if stereo) channels of the synth. This is equivalent to

```
playdate->sound->source->getVolume((SoundSource*)synth, outlvol, outrvol);
```

#### `int playdate->sound->synth->isPlaying(PDSynth* synth)`
*function*

Returns 1 if the synth is currently playing.

#### Synth parameters

Some synth types have parameters that can be set manually or driven by a signal, such as an envelope or LFO: On the square waveform the single parameter changes the pulse width; the PO synths have 2 parameters each, changing various aspects of the generator algorithm; and wavetable synths have up to four, described above.

#### `int playdate->sound->synth->getParameterCount(PDSynth* synth)`
*function*

Returns the number of parameters advertised by the synth.

#### `int playdate->sound->synth->setParameter(PDSynth* synth, int num, float value)`
*function*

Sets the (1-based) parameter at position _num_ to the given value. Returns 0 if _num_ is not a valid parameter index.

#### `void playdate->sound->synth->setParameterModulator(PDSynth* synth, int num, PDSynthSignalValue* mod)`
*function*

Sets a signal to modulate the parameter at index _num_. Set to _NULL_ to clear the modulator.

#### `PDSynthSignalValue* playdate->sound->synth->getParameterModulator(PDSynth* synth, int num)`
*function*

Returns the currently set parameter modulator for the given index.

#### PDSynthInstrument

PDSynthInstrument collects a number of PDSynth objects together to provide polyphony.

#### `PDSynthInstrument* playdate->sound->instrument->newInstrument(void)`
*function*

Creates a new PDSynthInstrument object.

#### `void playdate->sound->instrument->freeInstrument(PDSynthInstrument* instrument)`
*function*

Frees the given instrument, first removing it from the sound engine if needed.

#### `int playdate->sound->instrument->addVoice(PDSynthInstrument* instrument, PDSynth* synth, MIDINote rangeStart, MIDINote rangeEnd, float transpose)`
*function*

Adds the given PDSynth to the instrument. The synth will respond to playNote events between _rangeState_ and _rangeEnd_, inclusive. The _transpose_ argument is in half-step units, and is added to the instrument’s transpose parameter. The function returns 1 if successful, or 0 if the synth is already in another instrument or channel.

#### `PDSynth* playdate->sound->instrument->playNote(PDSynthInstrument* instrument, float frequency, float vel, float len, uint32_t when)`
*function*

#### `PDSynth* playdate->sound->instrument->playMIDINote(PDSynthInstrument* instrument, MIDINote note, float vel, float len, uint32_t when)`
*function*

The instrument passes the playNote/playMIDINote() event to the synth in its collection that has been off for the longest, or has been playing longest if all synths are currently playing. See also playdate→sound→synth→playNote(). The PDSynth that received the playNote event is returned.

#### `void playdate->sound->instrument->noteOff(PDSynthInstrument* instrument, MIDINote note, uint32_t when)`
*function*

Forwards the noteOff() event to the synth currently playing the given note. See also playdate→sound→synth→noteOff().

#### `void playdate->sound->instrument->setPitchBend(PDSynthInstrument* instrument, float amount)`
*function*

Sets the pitch bend to be applied to the voices in the instrument, as a fraction of the full range.

#### `void playdate->sound->instrument->setPitchBendRange(PDSynthInstrument* instrument, float halfSteps)`
*function*

Sets the pitch bend range for the voices in the instrument. The default range is 12, for a full octave.

#### `void playdate->sound->instrument->setTranspose(PDSynthInstrument* instrument, float halfSteps)`
*function*

Sets the transpose parameter for all voices in the instrument.

#### `void playdate->sound->instrument->allNotesOff(PDSynthInstrument* instrument, uint32_t when)`
*function*

Sends a noteOff event to all voices in the instrument.

#### `void playdate->sound->instrument->setVolume(PDSynthInstrument* instrument, float lvol, float rvol)`
*function*

#### `void playdate->sound->instrument->getVolume(PDSynthInstrument* instrument, float* outlvol, float* outrvol)`
*function*

Sets and gets the playback volume (0.0 - 1.0) for left and right channels of the synth. This is equivalent to

```
playdate->sound->source->setVolume((SoundSource*)instrument, lvol, rvol);
playdate->sound->source->getVolume((SoundSource*)instrument, &lvol, &rvol);
```

#### `int playdate->sound->instrument->activeVoiceCount(PDSynthInstrument* instrument)`
*function*

Returns the number of voices in the instrument currently playing.

#### Signals

A PDSynthSignalValue represents a signal that can be used as a modulator. Its PDSynthSignal subclass is used for "active" signals that change their values automatically. PDSynthLFO and PDSynthEnvelope are subclasses of PDSynthSignal.

#### `PDSynthSignal* playdate->sound->signal->newSignal(signalStepFunc step, signalNoteOnFunc noteOn, signalNoteOffFunc noteOff, signalDeallocFunc dealloc, void* userdata)`
*function*

```
typedef float (*signalStepFunc)(void* userdata, int* iosamples, float* ifval);
typedef void (*signalNoteOnFunc)(void* userdata, MIDINote note, float vel, float len); // len = -1 for indefinite
typedef void (*signalNoteOffFunc)(void* userdata, int stopped, int offset); // stopped = 0 on note release, = 1 when note actually stops playing; offset is # of frames into the current cycle
typedef void (*signalDeallocFunc)(void* userdata);
```

Provides a custom implementation for the signal. _signalStepFunc step_ is the only required function, returning the value at the end of the current frame. When called, the _ioframes_ pointer contains the number of samples until the end of the frame. If the signal needs to provide a value in the middle of the frame (e.g. an LFO that needs to be sample-accurate) it should return the "interframe" value in _ifval_ and set _iosamples_ to the sample offset of the value. The functions are called on the audio render thread, so they should return as quickly as possible.

#### `void playdate->sound->signal->freeSignal(PDSynthSignal* signal);`
*function*

Frees a signal created with _playdate→sound→signal→newSignal()_.

#### `float playdate->sound->signal->getValue(PDSynthSignal* signal);`
*function*

Returns the current output value of _signal_. The signal can be a custom signal created with newSignal(), or any of the PDSynthSignal subclasses.

#### `void playdate->sound->signal->setValueOffset(PDSynthSignal* signal, float offset);`
*function*

Offsets the signal’s output by the given amount.

#### `void playdate->sound->signal->setValueScale(PDSynthSignal* signal, float scale);`
*function*

Scales the signal’s output by the given factor. The scale is applied before the offset.

#### `PDSynthSignal* playdate->sound->signal->newSignalForValue(PDSynthSignalValue* value)`
*function*

Creates a new PDSynthSignal that tracks a PDSynthSignalValue.

#### LFO

#### `PDSynthLFO* playdate->sound->lfo->newLFO(LFOType type)`
*function*

Returns a new LFO object, which can be used to modulate sounds. The _type_ argument is one of the following values:

```
typedef enum
{
	kLFOTypeSquare,
	kLFOTypeTriangle,
	kLFOTypeSine,
	kLFOTypeSampleAndHold,
	kLFOTypeSawtoothUp,
	kLFOTypeSawtoothDown,
	kLFOTypeArpeggiator,
	kLFOTypeFunction
} LFOType;
```

#### `void playdate->sound->lfo->freeLFO(PDSynthLFO* lfo)`
*function*

Frees the LFO.

#### `void playdate->sound->lfo->setType(PDSynthLFO* lfo, LFOType type)`
*function*

Sets the LFO shape to one of the values given above.

#### `void playdate->sound->lfo->setRate(PDSynthLFO* lfo, float rate)`
*function*

Sets the LFO’s rate, in cycles per second.

#### `void playdate->sound->lfo->setPhase(PDSynthLFO* lfo, float phase)`
*function*

Sets the LFO’s phase, from 0 to 1.

#### `void playdate->sound->lfo->setStartPhase(PDSynthLFO* lfo, float phase)`
*function*

Sets the LFO’s initial phase, from 0 to 1.

#### `void playdate->sound->lfo->setCenter(PDSynthLFO* lfo, float center)`
*function*

Sets the center value for the LFO.

#### `void playdate->sound->lfo->setDepth(PDSynthLFO* lfo, float depth)`
*function*

Sets the depth of the LFO.

#### `void playdate->sound->lfo->setArpeggiation(PDSynthLFO* lfo, int nSteps, float* steps)`
*function*

Sets the LFO type to arpeggio, where the given values are in half-steps from the center note. For example, the sequence (0, 4, 7, 12) plays the notes of a major chord.

#### `void playdate->sound->lfo->setFunction(PDSynthLFO* lfo, float (*lfoFunc)(PDSynthLFO* lfo, void* userdata), void* userdata, int interpolate)`
*function*

Provides a custom function for LFO values.

#### `void playdate->sound->lfo->setDelay(PDSynthLFO* lfo, float holdoff, float ramptime)`
*function*

Sets an initial holdoff time for the LFO where the LFO remains at its center value, and a ramp time where the value increases linearly to its maximum depth. Values are in seconds.

#### `void playdate->sound->lfo->setRetrigger(PDSynthLFO* lfo, int flag)`
*function*

If retrigger is on, the LFO’s phase is reset to its initial phase (default 0) when a synth using the LFO starts playing a note.

#### `float playdate->sound->lfo->getValue(PDSynthLFO* lfo)`
*function*

Return the current output value of the LFO.

#### `void playdate->sound->lfo->setGlobal(PDSynthLFO* lfo, int global)`
*function*

If _global_ is set, the LFO is continuously updated whether or not it’s currently in use.

#### Envelope

#### `PDSynthEnvelope* playdate->sound->envelope->newEnvelope(float attack, float decay, float sustain, float release)`
*function*

Creates a new envelope with the given parameters.

#### `void playdate->sound->envelope->freeEnvelope(PDSynthEnvelope* env)`
*function*

Frees the envelope.

#### `void playdate->sound->envelope->setAttack(PDSynthEnvelope* env, float attack)`
*function*

#### `void playdate->sound->envelope->setDecay(PDSynthEnvelope* env, float decay)`
*function*

#### `void playdate->sound->envelope->setSustain(PDSynthEnvelope* env, float sustain)`
*function*

#### `void playdate->sound->envelope->setRelease(PDSynthEnvelope* env, float release)`
*function*

Sets the ADSR parameters of the envelope.

#### `void playdate->sound->envelope->setCurvature(PDSynthEnvelope* env, float amount)`
*function*

Smoothly changes the envelope’s shape from linear (amount=0) to exponential (amount=1).

#### `void playdate->sound->envelope->setVelocitySensitivity(PDSynthEnvelope* env, float velsens)`
*function*

Changes the amount by which note velocity scales output level. At the default value of 1, output is proportional to velocity; at 0 velocity has no effect on output level.

#### `void playdate->sound->envelope->setRateScaling(PDSynthEnvelope* env, float scaling, MIDINote start, MIDINote end)`
*function*

Scales the envelope rate according to the played note. For notes below `start`, the envelope’s set rate is used; for notes above `end` envelope rates are scaled by the `scaling` parameter. Between the two notes the scaling factor is interpolated from 1.0 to `scaling`.

#### `void playdate->sound->envelope->setLegato(PDSynthEnvelope* env, int flag)`
*function*

Sets whether to use legato phrasing for the envelope. If the legato flag is set, when the envelope is re-triggered before it’s released, it remains in the sustain phase instead of jumping back to the attack phase.

#### `void playdate->sound->envelope->setRetrigger(PDSynthEnvelope* env, int flag)`
*function*

If retrigger is on, the envelope always starts from 0 when a note starts playing, instead of the current value if it’s active.

#### `float playdate->sound->envelope->getValue(PDSynthEnvelope* env)`
*function*

Return the current output value of the envelope.

#### SoundEffect

_SoundEffect_ is the parent class of the sound effect types TwoPoleFilter, OnePoleFilter, BitCrusher, RingModulator, Overdrive, and DelayLine

#### `SoundEffect* playdate->sound->effect->newEffect(effectProc* proc, void* userdata)`
*function*

```
typedef int effectProc(SoundEffect* e, int32_t* left, int32_t* right, int nsamples, int bufactive);
```

Creates a new effect using the given processing function. _bufactive_ is 1 if samples have been set in the left or right buffers. The function should return 1 if it changed the buffer samples, otherwise 0. _left_ and _right_ (if the effect is on a stereo channel) are sample buffers in Q8.24 format.

#### `void playdate->sound->effect->freeEffect(SoundEffect* effect)`
*function*

Frees the given effect.

#### `void playdate->sound->effect->setMix(SoundEffect* effect, float level)`
*function*

Sets the wet/dry mix for the effect. A level of 1 (full wet) replaces the input with the effect output; 0 leaves the effect out of the mix (which is useful if you’re using a delay line with taps and don’t want to hear the delay line itself).

#### `void playdate->sound->effect->setMixModulator(SoundEffect* effect, PDSynthSignalValue* signal)`
*function*

Sets a signal to modulate the effect’s mix level. Set to _NULL_ to clear the modulator.

#### `PDSynthSignalValue* playdate->sound->effect->getMixModulator(SoundEffect* effect)`
*function*

Returns the current mix modulator for the effect.

#### `void playdate->sound->effect->setUserdata(SoundEffect* effect, void* userdata)`
*function*

#### `void* playdate->sound->effect->getUserdata(SoundEffect* effect)`
*function*

Sets or gets a userdata value for the effect.

#### TwoPoleFilter

#### `TwoPoleFilter* playdate->sound->effect->twopolefilter->newFilter(void)`
*function*

Creates a new two pole filter effect.

#### `void playdate->sound->effect->twopolefilter->freeFilter(TwoPoleFilter* filter)`
*function*

Frees the given filter.

#### `void playdate->sound->effect->twopolefilter->setType(TwoPoleFilter* filter, TwoPoleFilterType type)`
*function*

```
typedef enum
{
	kFilterTypeLowPass,
	kFilterTypeHighPass,
	kFilterTypeBandPass,
	kFilterTypeNotch,
	kFilterTypePEQ,
	kFilterTypeLowShelf,
	kFilterTypeHighShelf
} TwoPoleFilterType;
```

Sets the type of the filter.

#### `void playdate->sound->effect->twopolefilter->setFrequency(TwoPoleFilter* filter, float frequency)`
*function*

Sets the center/corner frequency of the filter. Value is in Hz.

#### `void playdate->sound->effect->twopolefilter->setFrequencyModulator(TwoPoleFilter* filter, PDSynthSignalValue* signal)`
*function*

Sets a signal to modulate the effect’s frequency. The signal is scaled so that a value of 1.0 corresponds to half the sample rate. Set to _NULL_ to clear the modulator.

#### `PDSynthSignalValue* playdate->sound->effect->twopolefilter->getFrequencyModulator(TwoPoleFilter* filter)`
*function*

Returns the filter’s current frequency modulator.

#### `void playdate->sound->effect->twopolefilter->setGain(TwoPoleFilter* filter, float gain)`
*function*

Sets the filter gain.

#### `void playdate->sound->effect->twopolefilter->setResonance(TwoPoleFilter* filter, float resonance)`
*function*

Sets the filter resonance.

#### `void playdate->sound->effect->twopolefilter->setResonanceModulator(TwoPoleFilter* filter, PDSynthSignalValue* signal)`
*function*

Sets a signal to modulate the filter resonance. Set to _NULL_ to clear the modulator.

#### `PDSynthSignalValue* playdate->sound->effect->twopolefilter->getResonanceModulator(TwoPoleFilter* filter)`
*function*

Returns the filter’s current resonance modulator.

#### OnePoleFilter

The one pole filter is a simple low/high pass filter, with a single parameter describing the cutoff frequency.

#### `OnePoleFilter* playdate->sound->effect->onepolefilter->newFilter(void)`
*function*

Creates a new one pole filter.

#### `void playdate->sound->effect->onepolefilter->freeFilter(OnePoleFilter* filter)`
*function*

Frees the filter.

#### `void playdate->sound->effect->onepolefilter->setParameter(OnePoleFilter* filter, float parameter)`
*function*

Sets the filter’s single parameter (cutoff frequency) to _p_. Values above 0 (up to 1) are high-pass, values below 0 (down to -1) are low-pass.

#### `void playdate->sound->effect->onepolefilter->setParameterModulator(OnePoleFilter* filter, PDSynthSignalValue* signal)`
*function*

Sets a signal to modulate the filter parameter. Set to _NULL_ to clear the modulator.

#### `PDSynthSignalValue* playdate->sound->effect->onepolefilter->getParameterModulator(OnePoleFilter* filter)`
*function*

Returns the filter’s current parameter modulator.

#### BitCrusher

#### `BitCrusher* playdate->sound->effect->bitcrusher->newBitCrusher(void)`
*function*

Returns a new BitCrusher effect.

#### `void playdate->sound->effect->bitcrusher->freeBitCrusher(BitCrusher* filter)`
*function*

Frees the given effect.

#### `void playdate->sound->effect->bitcrusher->setAmount(BitCrusher* filter, float amount)`
*function*

Sets the amount of crushing to _amount_. Valid values are 0 (no effect) to 1 (quantizing output to 1-bit).

#### `void playdate->sound->effect->bitcrusher->setAmountModulator(BitCrusher* filter, PDSynthSignalValue* signal)`
*function*

Sets a signal to modulate the crushing amount. Set to _NULL_ to clear the modulator.

#### `PDSynthSignalValue* playdate->sound->effect->bitcrusher->getAmountModulator(BitCrusher* filter)`
*function*

Returns the currently set modulator.

#### `void playdate->sound->effect->bitcrusher->setUndersampling(BitCrusher* filter, float undersample)`
*function*

Sets the number of samples to repeat, quantizing the input in time. A value of 0 produces no undersampling, 1 repeats every other sample, etc.

#### `void playdate->sound->effect->bitcrusher->setUndersampleModulator(BitCrusher* filter, PDSynthSignalValue* signal)`
*function*

Sets a signal to modulate the undersampling amount. Set to _NULL_ to clear the modulator.

#### `PDSynthSignalValue* playdate->sound->effect->bitcrusher->getUndersampleModulator(BitCrusher* filter)`
*function*

Returns the currently set modulator.

#### RingModulator

#### `RingModulator* playdate->sound->effect->ringmodulator->newRingmod(void)`
*function*

Returns a new ring modulator effect.

[[f-sound.effect.ringmodulator.freeRingmod]
.void playdate->sound->effect->ringmodulator->freeRingmod(RingModulator* filter)+*`

Frees the given effect.

#### `void playdate->sound->effect->ringmodulator->setFrequency(RingModulator* filter, float frequency)`
*function*

Sets the frequency of the modulation signal.

#### `void playdate->sound->effect->ringmodulator->setFrequencyModulator(RingModulator* filter, PDSynthSignalValue* signal)`
*function*

Sets a signal to modulate the frequency of the ring modulator. Set to _NULL_ to clear the modulator.

#### `PDSynthSignalValue* playdate->sound->effect->ringmodulator->getFrequencyModulator(RingModulator* filter)`
*function*

Returns the currently set frequency modulator.

#### Overdrive

#### `Overdrive* playdate->sound->effect->overdrive->newOverdrive(void)`
*function*

Returns a new overdrive effect.

#### `void playdate->sound->effect->overdrive->freeOverdrive(Overdrive* filter)`
*function*

Frees the given effect.

#### `void playdate->sound->effect->overdrive->setGain(Overdrive* filter, float gain)`
*function*

Sets the gain of the overdrive effect.

#### `void playdate->sound->effect->overdrive->setLimit(Overdrive* filter, float limit)`
*function*

Sets the level where the amplified input clips.

#### `void playdate->sound->effect->overdrive->setLimitModulator(Overdrive* filter, PDSynthSignalValue* signal)`
*function*

Sets a signal to modulate the limit parameter. Set to _NULL_ to clear the modulator.

#### `PDSynthSignalValue* playdate->sound->effect->overdrive->getLimitModulator(RingMoOverdrivedulator* filter)`
*function*

Returns the currently set limit modulator.

#### `void playdate->sound->effect->overdrive->setOffset(Overdrive* filter, float offset)`
*function*

Adds an offset to the upper and lower limits to create an asymmetric clipping.

#### `void playdate->sound->effect->overdrive->setOffsetModulator(Overdrive* filter, PDSynthSignalValue* signal)`
*function*

Sets a signal to modulate the offset parameter. Set to _NULL_ to clear the modulator.

#### `PDSynthSignalValue* playdate->sound->effect->overdrive->getOffsetModulator(RingMoOverdrivedulator* filter)`
*function*

Returns the currently set offset modulator.

#### DelayLine

#### `DelayLine* playdate->sound->effect->delayline->newDelayLine(int length, int stereo)`
*function*

Creates a new delay line effect. The _length_ parameter is given in samples.

#### `void playdate->sound->effect->delayline->freeDelayLine(DelayLine* delay)`
*function*

Frees the delay line.

#### `void playdate->sound->effect->delayline->setLength(DelayLine* d, int frames)`
*function*

Changes the length of the delay line, clearing its contents. This function reallocates the audio buffer, so it is not safe to call while the delay line is in use.

#### `void playdate->sound->effect->delayline->setFeedback(DelayLine* d, float fb)`
*function*

Sets the feedback level of the delay line.

#### `DelayLineTap* playdate->sound->effect->delayline->addTap(DelayLine* d, int delay)`
*function*

Returns a new tap on the delay line, at the given position. _delay_ must be less than or equal to the length of the delay line.

#### DelayLineTap

Note that DelayLineTap is a SoundSource, not a SoundEffect. A delay line tap can be added to any channel, not only the channel the delay line is on.

#### `void playdate->sound->effect->delayline->freeTap(DelayLineTap* tap)`
*function*

Frees a tap previously created with playdate→sound→delayline→addTap(), first removing it from the sound engine if needed.

#### `void playdate->sound->effect->delayline->setTapDelay(DelayLineTap* tap, int frames)`
*function*

Sets the position of the tap on the delay line, up to the delay line’s length.

#### `void playdate->sound->effect->delayline->setTapDelayModulator(DelayLineTap* tap, PDSynthSignalValue* mod)`
*function*

Sets a signal to modulate the tap delay. If the signal is continuous (e.g. an envelope or a triangle LFO, but not a square LFO) playback is sped up or slowed down to compress or expand time. Set to _NULL_ to clear the modulator.

#### `PDSynthSignalValue* playdate->sound->effect->delayline->getTapDelayModulator(DelayLineTap* tap)`
*function*

Returns the current delay modulator.

#### `void playdate->sound->effect->delayline->setTapChannelsFlipped(DelayLineTap* tap, int flip)`
*function*

If the delay line is stereo and _flip_ is set, the tap outputs the delay line’s left channel to its right output and vice versa.

#### SoundSequence

#### `SoundSequence* playdate->sound->sequence->newSequence(void)`
*function*

#### `void playdate->sound->sequence->freeSequence(SoundSequence* sequence)`
*function*

Creates or destroys a SoundSequence object.

#### `int playdate->sound->sequence->loadMIDIFile(SoundSequence* sequence, const char* path)`
*function*

If the sequence is empty, attempts to load data from the MIDI file at _path_ into the sequence. Returns 1 on success, 0 on failure.

#### `void playdate->sound->sequence->play(SoundSequence* sequence, SequenceFinishedCallback finishCallback, void* userdata)`
*function*

#### `void playdate->sound->sequence->stop(SoundSequence* sequence)`
*function*

Starts or stops playing the sequence. `finishCallback` is an optional function to be called when the sequence finishes playing or is stopped.

```
typedef void (*SequenceFinishedCallback)(SoundSequence* seq, void* userdata);
```

#### `int playdate->sound->sequence->isPlaying(SoundSequence* sequence)`
*function*

Returns 1 if the sequence is currently playing, otherwise 0.

#### `uint32_t playdate->sound->sequence->getTime(SoundSequence* sequence)`
*function*

#### `void playdate->sound->sequence->setTime(SoundSequence* sequence, uint32_t time)`
*function*

Gets or sets the current time in the sequence, in samples since the start of the file. Note that which step this moves the sequence to depends on the current tempo.

#### `void playdate->sound->sequence->setLoops(SoundSequence* sequence, int startstep, int endstep, int loops)`
*function*

Sets the looping range of the sequence. If _loops_ is 0, the loop repeats endlessly.

#### `float playdate->sound->sequence->getTempo(SoundSequence* sequence)`
*function*

#### `void playdate->sound->sequence->setTempo(SoundSequence* sequence, float stepsPerSecond)`
*function*

Sets or gets the tempo of the sequence, in steps per second.

#### `int playdate->sound->sequence->getLength(SoundSequence* sequence)`
*function*

Returns the length of the longest track in the sequence, in steps. See also playdate.sound.track.getLength().

#### `int playdate->sound->sequence->getTrackCount(SoundSequence* sequence)`
*function*

Returns the number of tracks in the sequence.

#### `SequenceTrack* playdate->sound->sequence->addTrack(SoundSequence* sequence)`
*function*

Adds the given playdate.sound.track to the sequence.

#### `SequenceTrack* playdate->sound->sequence->getTrackAtIndex(SoundSequence* sequence, unsigned int idx)`
*function*

#### `void playdate->sound->sequence->setTrackAtIndex(SoundSequence* sequence, SequenceTrack* track, unsigned int idx)`
*function*

Sets or gets the given SoundTrack object at position _idx_ in the sequence.

#### `void playdate->sound->sequence->allNotesOff(SoundSequence* sequence)`
*function*

Sends a stop signal to all playing notes on all tracks.

#### `int playdate->sound->sequence->getCurrentStep(SoundSequence* sequence, int* timeOffset)`
*function*

Returns the step number the sequence is currently at. If _timeOffset_ is not NULL, its contents are set to the current sample offset within the step.

#### `void playdate->sound->sequence->setCurrentStep(SoundSequence* seq, int step, int timeOffset, int playNotes)`
*function*

Set the current step for the sequence. _timeOffset_ is a sample offset within the step. If _playNotes_ is set, notes at the given step (ignoring _timeOffset_) are played.

#### ControlSignal

_ControlSignal_ is a subclass of PDSynthSignal used for sequencing changes to parameters.

#### `ControlSignal* playdate->sound->controlsignal->newSignal(void)`
*function*

Creates a new control signal object.

#### `void playdate->sound->controlsignal->freeSignal(ControlSignal* signal)`
*function*

Frees the given signal.

#### `void playdate->sound->controlsignal->clearEvents(ControlSignal* signal)`
*function*

Clears all events from the given signal.

#### `void playdate->sound->controlsignal->addEvent(ControlSignal* signal, int step, float value, int interpolate)`
*function*

Adds a value to the signal’s timeline at the given step. If _interpolate_ is set, the value is interpolated between the previous step+value and this one.

#### `void playdate->sound->controlsignal->removeEvent(ControlSignal* signal, int step)`
*function*

Removes the control event at the given step.

#### `int playdate->sound->controlsignal->getMIDIControllerNumber(ControlSignal* signal)`
*function*

Returns the MIDI controller number for this ControlSignal, if it was created from a MIDI file via playdate→sound→sequence→loadMIDIFile().

#### SequenceTrack

A _SequenceTrack_ comprises a PDSynthInstrument, a sequence of notes to play on that instrument, and any number of ControlSignal objects to control parameter changes.

#### `SequenceTrack* playdate->sound->track->newTrack(void)`
*function*

Returns a new SequenceTrack.

#### `void playdate->sound->track->freeTrack(SequenceTrack* track)`
*function*

Frees the SequenceTrack.

#### `void playdate->sound->track->setInstrument(SequenceTrack* track, PDSynthInstrument* instrument)`
*function*

#### `PDSynthInstrument* playdate->sound->track->getInstrument(SequenceTrack* track)`
*function*

Sets or gets the PDSynthInstrument assigned to the track.

#### `void playdate->sound->track->addNoteEvent(SequenceTrack* track, uint32_t step, uint32_t length, MIDINote note, float vel)`
*function*

Adds a single note event to the track.

#### `void playdate->sound->track->removeNoteEvent(SequenceTrack* track, uint32_t step, MIDINote note)`
*function*

Removes the event at _step_ playing _note_.

#### `void playdate->sound->track->clearNotes(SequenceTrack* track)`
*function*

Clears all notes from the track.

#### `int playdate->sound->track->getLength(SequenceTrack* track)`
*function*

Returns the length, in steps, of the track—​that is, the step where the last note in the track ends.

#### `int playdate->sound->track->getIndexForStep(SequenceTrack* track, uint32_t step)`
*function*

Returns the internal array index for the first note at the given step.

#### `int playdate->sound->track->getNoteAtIndex(SequenceTrack* track, int index, uint32_t* outStep, uint32_t* outLen, MIDINote* outNote, float* outVelocity)`
*function*

If the given index is in range, sets the data in the out pointers and returns 1; otherwise, returns 0.

#### `void playdate->sound->track->getControlSignalCount(SequenceTrack* track)`
*function*

Returns the number of ControlSignal objects in the track.

#### `void playdate->sound->track->getControlSignal(SequenceTrack* track, int idx)`
*function*

Returns the ControlSignal at index _idx_.

#### `void playdate->sound->track->getSignalForController(SequenceTrack* track, int controller, int create)`
*function*

Returns the ControlSignal for MIDI controller number _controller_, creating it if the **create** flag is set and it doesn’t yet exist.

#### `void playdate->sound->track->clearControlEvents(SequenceTrack* track)`
*function*

Clears all ControlSignals from the track.

#### `int playdate->sound->track->activeVoiceCount(SequenceTrack* track)`
*function*

Returns the number of voices currently playing in the track’s instrument.

#### `int playdate->sound->track->getPolyphony(SequenceTrack* track)`
*function*

Returns the maximum number of simultaneously playing notes in the track. (Currently, this value is only set when the track was loaded from a MIDI file. We don’t yet track polyphony for user-created events.)

#### `void playdate->sound->track->setMuted(SequenceTrack* track, int mute)`
*function*

Mutes or unmutes the track.

### 7.3. Display

#### `int playdate->display->getHeight(void)`
*function*

Returns the height of the display, taking the current scale into account; e.g., if the scale is 2, this function returns 120 instead of 240.

Equivalent to `playdate.display.getHeight()` in the Lua API.

#### `int playdate->display->getWidth(void)`
*function*

Returns the width of the display, taking the current scale into account; e.g., if the scale is 2, this function returns 200 instead of 400.

Equivalent to `playdate.display.getWidth()` in the Lua API.

#### `void playdate->display->setInverted(int flag)`
*function*

If _flag_ evaluates to true, the frame buffer is drawn inverted—black instead of white, and vice versa.

Equivalent to `playdate.display.setInverted()` in the Lua API.

#### `void playdate->display->setMosaic(unsigned int x, unsigned int y)`
*function*

Adds a mosaic effect to the display. Valid _x_ and _y_ values are between 0 and 3, inclusive.

Equivalent to `playdate.display.setMosaic` in the Lua API.

#### `void playdate->display->setFlipped(int x, int y)`
*function*

Flips the display on the x or y axis, or both.

Equivalent to `playdate.display.setFlipped()` in the Lua API.

#### `void playdate->display->setRefreshRate(float rate)`
*function*

Sets the nominal refresh rate in frames per second. The default is 30 fps, which is a recommended figure that balances animation smoothness with performance and power considerations. Maximum is 50 fps.

If _rate_ is 0, the game’s update callback (either Lua’s `playdate.update()` or the function specified by playdate→system→setUpdateCallback()) is called as soon as possible. Since the display refreshes line-by-line, and unchanged lines aren’t sent to the display, the update cycle will be faster than 30 times a second but at an indeterminate rate.

Equivalent to `playdate.display.setRefreshRate()` in the Lua API.

#### `float playdate->display->getRefreshRate()`
*function*

Returns the current nominal display refresh rate. This is the frame rate the device is targeting, and does not account for lag due to (for example) code running too slow. To get the real time frame rate, use playdate→display→getFPS().

Equivalent to `playdate.display.getRefreshRate()` in the Lua API.

#### `float playdate->display->getFPS()`
*function*

Returns the _measured, actual_ refresh rate in frames per second. This value may be different from the _specified_ refresh rate (see playdate→display→getRefreshRate()) by a little or a lot depending upon how much calculation is being done per frame.

Equivalent to `playdate.display.getFPS()` in the Lua API.

#### `void playdate->display->setScale(unsigned int s)`
*function*

Sets the display scale factor. Valid values for _scale_ are 1, 2, 4, and 8.

The top-left corner of the frame buffer is scaled up to fill the display; e.g., if the scale is set to 4, the pixels in rectangle [0,100] x [0,60] are drawn on the screen as 4 x 4 squares.

Equivalent to `playdate.display.setScale()` in the Lua API.

#### `void playdate->display->setOffset(int dx, int dy)`
*function*

Offsets the display by the given amount. Areas outside of the displayed area are filled with the current background color.

Equivalent to `playdate.display.setOffset()` in the Lua API.

### 7.4. Filesystem

#### `const char* playdate->file->geterr(void);`
*function*

Returns human-readable text describing the most recent error (usually indicated by a -1 return from a filesystem function).

#### `int playdate->file->listfiles(const char* path, void (*callback)(const char* filename, void* userdata), void* userdata, int showhidden);`
*function*

Calls the given callback function for every file at _path_. Subfolders are indicated by a trailing slash '/' in _filename_. _listfiles()_ does not recurse into subfolders. If _showhidden_ is set, files beginning with a period will be included; otherwise, they are skipped. Returns 0 on success, -1 if no folder exists at _path_ or it can’t be opened.

Equivalent to `playdate.file.listFiles()` in the Lua API.

#### `int playdate->file->unlink(const char* path, int recursive);`
*function*

Deletes the file at _path_. Returns 0 on success, or -1 in case of error. If recursive is 1 and the target path is a folder, this deletes everything inside the folder (including folders, folders inside those, and so on) as well as the folder itself.

#### `int playdate->file->mkdir(const char* path);`
*function*

Creates the given _path_ in the Data/<gameid> folder. It does not create intermediate folders. Returns 0 on success, or -1 in case of error.

Equivalent to `playdate.file.mkdir()` in the Lua API.

#### `int playdate->file->rename(const char* from, const char* to);`
*function*

Renames the file at _from_ to _to_. It will overwrite the file at _to_ without confirmation. It does not create intermediate folders. Returns 0 on success, or -1 in case of error.

Equivalent to `playdate.file.rename()` in the Lua API.

#### `int playdate->file->stat(const char* path, FileStat* stat);`
*function*

Populates the FileStat _stat_ with information about the file at _path_. Returns 0 on success, or -1 in case of error.

```
typedef struct
{
	int isdir;
	unsigned int size;
	int m_year;
	int m_month;
	int m_day;
	int m_hour;
	int m_minute;
	int m_second;
} FileStat;
```

#### File Handles

#### `SDFile* playdate->file->open(const char* path, FileOptions mode);`
*function*

Opens a handle for the file at _path_. The _kFileRead_ mode opens a file in the game pdx, while _kFileReadData_ searches the game’s data folder; to search the data folder first then fall back on the game pdx, use the bitwise combination _kFileRead|kFileReadData_._kFileWrite_ and _kFileAppend_ always write to the data folder. The function returns NULL if a file at _path_ cannot be opened, and playdate->file->geterr() will describe the error. The filesystem has a limit of 64 simultaneous open files. The returned file handle should be closed, not freed, when it is no longer in use.

```
typedef enum
{
	kFileRead,
	kFileReadData,
	kFileWrite,
	kFileAppend
} FileOptions;
```

Equivalent to `playdate.file.open()` in the Lua API.

#### `int playdate->file->close(SDFile* file);`
*function*

Closes the given _file_ handle. Returns 0 on success, or -1 in case of error.

Equivalent to `playdate.file.close()` in the Lua API.

#### `int playdate->file->flush(SDFile* file);`
*function*

Flushes the output buffer of _file_ immediately. Returns the number of bytes written, or -1 in case of error.

Equivalent to `playdate.file.flush()` in the Lua API.

#### `int playdate->file->read(SDFile* file, void* buf, unsigned int len);`
*function*

Reads up to _len_ bytes from the _file_ into the buffer _buf_. Returns the number of bytes read (0 indicating end of file), or -1 in case of error.

Equivalent to `playdate.file.file:read()` in the Lua API.

#### `int playdate->file->seek(SDFile* file, int pos, int whence);`
*function*

Sets the read/write offset in the given _file_ handle to _pos_, relative to the _whence_ macro. SEEK_SET is relative to the beginning of the file, SEEK_CUR is relative to the current position of the file pointer, and SEEK_END is relative to the end of the file. Returns 0 on success, -1 on error.

Equivalent to `playdate.file.file:seek()` in the Lua API.

#### `int playdate->file->tell(SDFile* file);`
*function*

Returns the current read/write offset in the given _file_ handle, or -1 on error.

Equivalent to `playdate.file.file:tell()` in the Lua API.

#### `int playdate->file->write(SDFile* file, const void* buf, unsigned int len);`
*function*

Writes the buffer of bytes _buf_ to the _file_. Returns the number of bytes written, or -1 in case of error.

Equivalent to `playdate.file.file:write()` in the Lua API.

### 7.5. Graphics

The drawing functions use a context stack to select the drawing target, for setting a stencil, changing the draw mode, etc. The stack is unwound at the beginning of each update cycle, with drawing restored to target the display.

#### `void playdate->graphics->pushContext(LCDBitmap* target);`
*function*

Push a new drawing context for drawing into the given bitmap. If _target_ is _NULL_, the drawing functions will use the display framebuffer.

Equivalent to `playdate.graphics.pushContext()` in the Lua API.

#### `void playdate->graphics->popContext(void);`
*function*

Pops a context off the stack (if any are left), restoring the drawing settings from before the context was pushed.

Equivalent to `playdate.graphics.popContext()` in the Lua API.

#### `void playdate->graphics->setStencil(LCDBitmap* stencil);`
*function*

Sets the stencil used for drawing: While the stencil is active, drawing functions will only draw pixels where the stencil is white and nothing is drawn where the stencil is black. For a tiled stencil, use _setStencilImage()_ instead. To clear the stencil, set it to _NULL_.

#### `void playdate->graphics->setStencilImage(LCDBitmap* stencil, int tile);`
*function*

Sets the stencil used for drawing: While the stencil is active, drawing functions will only draw pixels where the stencil is white and nothing is drawn where the stencil is black. If the _tile_ flag is set the stencil image will be tiled. Tiled stencils must have width equal to a multiple of 32 pixels. To clear the stencil, call `playdate→graphics→setStencil(NULL);`.

Equivalent to `playdate.graphics.setStencilImage()` in the Lua API.

#### `LCDBitmapDrawMode playdate->graphics->setDrawMode(LCDBitmapDrawMode mode);`
*function*

Sets the mode used for drawing bitmaps. Note that text drawing uses bitmaps, so this affects how fonts are displayed as well. Returns the previous draw mode, in case you need to restore it after drawing.

```
typedef enum
{
	kDrawModeCopy,
	kDrawModeWhiteTransparent,
	kDrawModeBlackTransparent,
	kDrawModeFillWhite,
	kDrawModeFillBlack,
	kDrawModeXOR,
	kDrawModeNXOR,
	kDrawModeInverted
} LCDBitmapDrawMode;
```

Equivalent to `playdate.graphics.setImageDrawMode()` in the Lua API.

#### `void playdate->graphics->setClipRect(int x, int y, int width, int height);`
*function*

Sets the current clip rect, using world coordinates—​that is, the given rectangle will be translated by the current drawing offset. The clip rect is cleared at the beginning of each update.

Equivalent to `playdate.graphics.setClipRect()` in the Lua API.

#### `void playdate->graphics->setScreenClipRect(int x, int y, int width, int height);`
*function*

Sets the current clip rect in screen coordinates.

Equivalent to `playdate.graphics.setScreenClipRect()` in the Lua API.

#### `void playdate->graphics->clearClipRect(void);`
*function*

Clears the current clip rect.

Equivalent to `playdate.graphics.clearClipRect()` in the Lua API.

#### `void playdate->graphics->setLineCapStyle(LCDLineCapStyle endCapStyle);`
*function*

Sets the end cap style used in the line drawing functions.

```
typedef enum
{
	kLineCapStyleButt,
	kLineCapStyleSquare,
	kLineCapStyleRound
} LCDLineCapStyle;
```

Equivalent to `playdate.graphics.setLineCapStyle()` in the Lua API.

#### `void playdate->graphics->setFont(LCDFont* font);`
*function*

Sets the font to use in subsequent drawText calls.

Equivalent to `playdate.graphics.setFont()` in the Lua API.

#### `void playdate->graphics->setTextTracking(int tracking);`
*function*

Sets the tracking to use when drawing text.

Equivalent to `playdate.graphics.font:setTracking()` in the Lua API.

#### `int playdate->graphics->getTextTracking(void);`
*function*

Gets the tracking used when drawing text.

Equivalent to `playdate.graphics.font:getTracking()` in the Lua API.

#### `void playdate->graphics->setTextLeading(int leading);`
*function*

Sets the leading adjustment (added to the leading specified in the font) to use when drawing text.

Equivalent to `playdate.graphics.font:setLeading()` in the Lua API.

#### Supporting types

```
Either an LCDSolidColor or an LCDPattern*.
```

```
typedef enum
{
	kColorBlack,
	kColorWhite,
	kColorClear,
	kColorXOR
} LCDSolidColor;
```

```
typedef uint8_t LCDPattern[16];
```

```
typedef enum
{
	kBitmapUnflipped,
	kBitmapFlippedX,
	kBitmapFlippedY,
	kBitmapFlippedXY
} LCDBitmapFlip;
```

```
typedef struct
{
	int left;
	int right;
	int top;
	int bottom;
} LCDRect;
```

```
typedef struct
{
	float x;
	float y;
	float width;
	float height;
} PDRect;
```

#### Bitmaps

#### `void playdate->graphics->clearBitmap(LCDBitmap* bitmap, LCDColor bgcolor);`
*function*

Clears _bitmap_, filling with the given _bgcolor_.

#### `LCDBitmap* playdate->graphics->copyBitmap(LCDBitmap* bitmap);`
*function*

Returns a new LCDBitmap that is an exact copy of _bitmap_.

#### `int playdate->graphics->checkMaskCollision(LCDBitmap* bitmap1, int x1, int y1, LCDBitmapFlip flip1, LCDBitmap* bitmap2, int x2, int y2, LCDBitmapFlip flip2, LCDRect rect);`
*function*

Returns 1 if any of the opaque pixels in _bitmap1_ when positioned at _x1_, _y1_ with _flip1_ overlap any of the opaque pixels in _bitmap2_ at _x2_, _y2_ with _flip2_ within the non-empty _rect_, or 0 if no pixels overlap or if one or both fall completely outside of _rect_.

#### `void playdate->graphics->drawBitmap(LCDBitmap* bitmap, int x, int y, LCDBitmapFlip flip);`
*function*

Draws the _bitmap_ with its upper-left corner at location _x_, _y_, using the given flip orientation.

#### `void playdate->graphics->drawScaledBitmap(LCDBitmap* bitmap, int x, int y, float xscale, float yscale);`
*function*

Draws the _bitmap_ scaled to _xscale_ and _yscale_ with its upper-left corner at location _x_, _y_. Note that _flip_ is not available when drawing scaled bitmaps but negative scale values will achieve the same effect.

#### `void playdate->graphics->drawRotatedBitmap(LCDBitmap* bitmap, int x, int y, float degrees, float centerx, float centery, float xscale, float yscale);`
*function*

Draws the _bitmap_ scaled to _xscale_ and _yscale_ then rotated by _degrees_ with its center as given by proportions _centerx_ and _centery_ at _x_, _y_; that is: if _centerx_ and _centery_ are both 0.5 the center of the image is at (_x_,_y_), if _centerx_ and _centery_ are both 0 the top left corner of the image (before rotation) is at (_x_,_y_), etc.

#### `void playdate->graphics->freeBitmap(LCDBitmap*);`
*function*

Frees the given _bitmap_.

#### `void playdate->graphics->getBitmapData(LCDBitmap* bitmap, int* width, int* height, int* rowbytes, uint8_t** mask, uint8_t** data);`
*function*

Gets various info about _bitmap_ including its _width_ and _height_ and raw pixel data. The data is 1 bit per pixel packed format, in MSB order; in other words, the high bit of the first byte in `data` is the top left pixel of the image. If the bitmap has a mask, a pointer to its data is returned in _mask_, else NULL is returned.

#### `LCDSolidColor playdate->graphics->getBitmapPixel(LCDBitmap* bitmap, int x, int y);`
*function*

Gets the color of the pixel at _(x,y)_ in the given _bitmap_. If the coordinate is outside the bounds of the bitmap, or if the bitmap has a mask and the pixel is marked transparent, the function returns `kColorClear`; otherwise the return value is `kColorWhite` or `kColorBlack`.

#### `LCDBitmap* playdate->graphics->loadBitmap(const char* path, const char** outerr);`
*function*

Allocates and returns a new LCDBitmap from the file at _path_. If there is no file at _path_, the function returns null.

#### `void playdate->graphics->loadIntoBitmap(const char* path, LCDBitmap* bitmap, const char** outerr);`
*function*

Loads the image at _path_ into the previously allocated _bitmap_.

#### `LCDBitmap* playdate->graphics->newBitmap(int width, int height, LCDColor bgcolor);`
*function*

Allocates and returns a new _width_ by _height_ LCDBitmap filled with _bgcolor_.

#### `void playdate->graphics->tileBitmap(LCDBitmap* bitmap, int x, int y, int width, int height, LCDBitmapFlip flip);`
*function*

Draws the _bitmap_ with its upper-left corner at location _x_, _y_ tiled inside a _width_ by _height_ rectangle.

#### `LCDBitmap* playdate->graphics->rotatedBitmap(LCDBitmap* bitmap, float rotation, float xscale, float yscale, int* allocedSize);`
*function*

Returns a new, rotated and scaled LCDBitmap based on the given _bitmap_.

#### `int playdate->graphics->setBitmapMask(LCDBitmap* bitmap, LCDBitmap* mask);`
*function*

Sets a mask image for the given _bitmap_. The set mask must be the same size as the target bitmap. Returns 1 on success, 0 on failure (i.e. if either bitmap is NULL or the sizes don’t match).

#### `LCDBitmap* playdate->graphics->getBitmapMask(LCDBitmap* bitmap);`
*function*

Gets a mask image for the given _bitmap_, or returns NULL if the _bitmap_ doesn’t have a mask layer. The returned image points to _bitmap_'s data, so drawing into the mask image affects the source bitmap directly. The caller takes ownership of the returned LCDBitmap and is responsible for freeing it when it’s no longer in use.

#### BitmapTables

#### `LCDBitmap* playdate->graphics->getTableBitmap(LCDBitmapTable* table, int idx);`
*function*

Returns the _idx_ bitmap in _table_, If _idx_ is out of bounds, the function returns NULL.

#### `LCDBitmapTable* playdate->graphics->loadBitmapTable(const char* path, const char** outerr);`
*function*

Allocates and returns a new LCDBitmap from the file at _path_. If there is no file at _path_, the function returns null.

#### `void playdate->graphics->loadIntoBitmapTable(const char* path, LCDBitmapTable* table, const char** outerr);`
*function*

Loads the imagetable at _path_ into the previously allocated _table_.

#### `LCDBitmapTable* playdate->graphics->newBitmapTable(int count, int width, int height);`
*function*

Allocates and returns a new LCDBitmapTable that can hold _count_ _width_ by _height_ LCDBitmaps.

#### `void playdate->graphics->freeBitmapTable(LCDBitmapTable* table);`
*function*

Frees the given bitmap table. Note that this will invalidate any bitmaps returned by `getTableBitmap()`.

#### `void playdate->graphics->getBitmapTableInfo(LCDBitmapTable* table, int* count, int* cellswide);`
*function*

Returns the bitmap table’s image count in the _count_ pointer (if not NULL) and number of cells across in the _cellswide_ pointer (ditto).

#### Fonts & Text

#### `int playdate->graphics->drawText(const void* text, size_t len, PDStringEncoding encoding, int x, int y);`
*function*

Draws the given text using the provided options. If no font has been set with setFont, the default system font Asheville Sans 14 Light is used. Note that `len` is the length of the **decoded** string—​that is, the number of codepoints in the string, not the number of bytes; however, since the parser stops at the NUL terminator it’s safe to pass `strlen(text)` in here when you want to draw the entire string.

Equivalent to `playdate.graphics.drawText()` in the Lua API.

#### `int playdate->graphics->drawTextInRect(const void* text, size_t len, PDStringEncoding encoding, int x, int y, int width, int height, PDTextWrappingMode wrap, PDTextAlignment align);`
*function*

Draws the text in the given rectangle using the provided options. If no font has been set with setFont, the default system font Asheville Sans 14 Light is used. See the above note about the `len` argument.

The _wrap_ argument is one of

```
typedef enum
{
	kWrapClip,
	kWrapCharacter,
	kWrapWord,
} PDTextWrappingMode;
```

and _align_ is one of

```
typedef enum
{
	kAlignTextLeft,
	kAlignTextCenter,
	kAlignTextRight
} PDTextAlignment;
```

#### `uint8_t playdate->graphics->getFontHeight(LCDFont* font);`
*function*

Returns the height of the given font.

#### `LCDFontPage* playdate->graphics->getFontPage(LCDFont* font, uint32_t c);`
*function*

Returns an LCDFontPage object for the given character code. Each LCDFontPage contains information for 256 characters; specifically, if `(c1 & ~0xff) == (c2 & ~0xff)`, then _c1_ and _c2_ belong to the same page and the same LCDFontPage can be used to fetch the character data for both instead of searching for the page twice.

#### `LCDFontGlyph* playdate->graphics->getPageGlyph(LCDFontPage* page, uint32_t c, LCDBitmap** bitmap, int* advance);`
*function*

Returns an LCDFontGlyph object for character _c_ in LCDFontPage _page_, and optionally returns the glyph’s bitmap and advance value.

#### `int playdate->graphics->getGlyphKerning(LCDFontGlyph* glyph, uint32_t c1, uint32_t c2);`
*function*

Returns the kerning adjustment between characters _c1_ and _c2_ as specified by the font.

#### `int playdate->graphics->getTextWidth(LCDFont* font, const void* text, size_t len, PDStringEncoding encoding, int tracking);`
*function*

Returns the width of the given text in the given font. See the note above about the `len` argument.

```
typedef enum
{
	kASCIIEncoding,
	kUTF8Encoding,
	k16BitLEEncoding
} PDStringEncoding;
```

#### `int playdate->graphics->getTextHeightForMaxWidth(LCDFont* font, const void* text, size_t len, int maxwidth, PDStringEncoding encoding, PDTextWrappingMode wrap, int tracking, int extraLeading);`
*function*

Returns the height of _text_ in the given _font_, when wrapped to _maxwidth_ using the wrapping mode _wrap_. See the note above about the `len` argument.

#### `LCDFont* playdate->graphics->loadFont(const char* path, const char** outErr);`
*function*

Returns the LCDFont object for the font file at _path_. In case of error, _outErr_ points to a string describing the error. The returned font can be freed with playdate→system→realloc(font, 0) when it is no longer in use.

#### `LCDFont* playdate->graphics->makeFontFromData(LCDFontData* data, int wide);`
*function*

Returns an LCDFont object wrapping the LCDFontData _data_ comprising the contents (minus 16-byte header) of an uncompressed pft file. _wide_ corresponds to the flag in the header indicating whether the font contains glyphs at codepoints above U+1FFFF.

#### Geometry

#### `void playdate->graphics->drawEllipse(int x, int y, int width, int height, int lineWidth, float startAngle, float endAngle, LCDColor color);`
*function*

Draws an ellipse inside the rectangle {x, y, width, height} of width _lineWidth_ (inset from the rectangle bounds). If _startAngle_ != _endAngle, this draws an arc between the given angles. Angles are given in degrees, clockwise from due north.

#### `void playdate->graphics->fillEllipse(int x, int y, int width, int height, float startAngle, float endAngle, LCDColor color);`
*function*

Fills an ellipse inside the rectangle {x, y, width, height}. If _startAngle_ != _endAngle, this draws a wedge/Pacman between the given angles. Angles are given in degrees, clockwise from due north.

#### `void playdate->graphics->drawLine(int x1, int y1, int x2, int y2, int width, LCDColor color);`
*function*

Draws a line from _x1_, _y1_ to _x2_, _y2_ with a stroke width of _width_.

Equivalent to `playdate.graphics.drawLine()` in the Lua API.

#### `void playdate->graphics->drawRect(int x, int y, int width, int height, LCDColor color);`
*function*

Draws a _width_ by _height_ rect at _x_, _y_.

Equivalent to `playdate.graphics.drawRect()` in the Lua API.

#### `void playdate->graphics->fillRect(int x, int y, int width, int height, LCDColor color);`
*function*

Draws a filled _width_ by _height_ rect at _x_, _y_.

Equivalent to `playdate.graphics.fillRect()` in the Lua API.

#### `void playdate->graphics->fillTriangle(int x1, int y1, int x2, int y2, int x3, int y3, LCDColor color);`
*function*

Draws a filled triangle with points at _x1_, _y1_, _x2_, _y2_, and _x3_, _y3_.

```
typedef enum
{
	kPolygonFillNonZero,
	kPolygonFillEvenOdd
} LCDPolygonFillRule;
```

Equivalent to `playdate.graphics.fillTriangle()` in the Lua API.

#### `void playdate->graphics->fillPolygon(int nPoints, int* points, LCDColor color, LCDPolygonFillRule fillrule);`
*function*

Fills the polygon with vertices at the given coordinates (an array of 2*`nPoints` ints containing alternating x and y values) using the given color and fill, or winding, rule. See [https://en.wikipedia.org/wiki/Nonzero-rule](https://en.wikipedia.org/wiki/Nonzero-rule) for an explanation of the winding rule. An edge between the last vertex and the first is assumed.

Equivalent to `playdate.graphics.fillPolygon()` in the Lua API.

#### `void playdate->graphics->drawRoundRect(int x, int y, int width, int height, int radius, int lineWidth, LCDColor color);`
*function*

Draws a rectangle with rounded corners inside the rect with origin (_x_, _y_) and size (_width_, _height_) using the given _lineWidth_, _color_, and corner _radius_.

Equivalent to `playdate.graphics.drawRoundRect()` in the Lua API.

#### `void playdate->graphics->fillRoundRect(int x, int y, int width, int height, int radius, LCDColor color);`
*function*

Draws a filled rectangle with rounded corners in the rect with origin (_x_, _y_) and size (_width_, _height_) using the given _color_, and corner _radius_.

Equivalent to `playdate.graphics.fillRoundRect()` in the Lua API.

### 7.6. Networking

Playdate OS 2.7 adds support for both HTTP and TCP networking. The device supports up to four simultaneous connections.

#### `void playdate->network->setEnabled(bool flag, void (*callback)(PDNetErr err));`
*function*

Playdate will connect to the configured access point automatically as needed and turn off the wifi radio after a 30 second idle timeout. This function allows a game to start connecting to the access point sooner, since that can take upwards of 10 seconds, or turn off wifi as soon as it’s no longer needed instead of waiting 30 seconds. If `flag` is true, a callback function can be provided to check for an error connecting to the access point.

```
typedef enum {
	NET_OK = 0,
	NET_NO_DEVICE = -1,
	NET_BUSY = -2,
	NET_WRITE_ERROR = -3,
	NET_WRITE_BUSY = -4,
	NET_WRITE_TIMEOUT = -5,
	NET_READ_ERROR = -6,
	NET_READ_BUSY = -7,
	NET_READ_TIMEOUT = -8,
	NET_READ_OVERFLOW = -9,
	NET_FRAME_ERROR = -10,
	NET_BAD_RESPONSE = -11,
	NET_ERROR_RESPONSE = -12,
	NET_RESET_TIMEOUT = -13,
	NET_BUFFER_TOO_SMALL = -14,
	NET_UNEXPECTED_RESPONSE = -15,
	NET_NOT_CONNECTED_TO_AP = -16,
	NET_NOT_IMPLEMENTED = -17,
	NET_CONNECT_TIMEOUT = -18,
	NET_CONNECTION_CLOSED = -19,
	NET_PERMISSION_DENIED = -20,
} PDNetErr;
```

Returns a value from the following:

```
typedef enum {
	kWifiNotConnected,  // Not connected to an AP
	kWifiConnected,     // Device is connected to an AP
	kWifiNotAvailable,  // No configured AP is available
} WifiStatus;
```

#### HTTP

#### `enum accessReply playdate->network->http->requestAccess(const char* server, int port, bool usessl, const char* purpose, AccessRequestCallback* requestCallback, void* userdata);`
*function*

```
typedef void AccessRequestCallback(bool allowed, void* userdata);
```

Before connecting to a server, permission must be given by the user. Unlike in Lua, we don’t have a way to pause the runtime to present the modal dialog, so this function must be explicitly called before calling http→newConnection(). `server` can be a parent domain of the connections opened, or NULL to request access to any HTTP server. `purpose` is an optional string displayed in the permissions dialog to explain why the program is requesting access. After the user responds to the request, `requestCallback` is called with the given `userdata` argument. The return value is one of the following:

```
enum accessReply
{
	kAccessAsk,
	kAccessDeny,
	kAccessAllow
};
```

#### `HTTPConnection* playdate->network->http->newConnection(const char* server, int port, bool usessl);`
*function*

Returns an `HTTPConnection` object for connecting to the given server, or NULL if permission has been denied or not yet granted. If `port` is 0, the connection will use port 80 if `usessl` is false, otherwise 443. No connection is attempted until get() or post() are called.

#### `HTTPConnection* playdate->network->http->retain(HTTPConnection* connection);`
*function*

Adds 1 to the connection’s retain count, so that it won’t be freed when it scopes out of another context. This is used primarily so we can pass a connection created in Lua into C and not have to worry about the Lua wrapper’s lifespan.

#### `void playdate->network->http->release(HTTPConnection* connection);`
*function*

Releases a previous retain on the connection.

#### `void playdate->network->http->setConnectTimeout(HTTPConnection* connection, int ms);`
*function*

Sets the length of time (in milliseconds) to wait for the connection to the server to be made.

#### `void playdate->network->http->setKeepAlive(HTTPConnection* connection, bool keepalive);`
*function*

If `keepalive` is true, this causes the HTTP request to include a _Connection: keep-alive_ header.

#### `void playdate->network->http->setByteRange(HTTPConnection* connection, int start, int end);`
*function*

Adds a `Range: bytes=<start>-<end>` header to the HTTP request.

#### `void playdate->network->http->setUserdata(HTTPConnection* connection, void* userdata);`
*function*

Sets a custom userdata on the connection.

#### `void* playdate->network->http->getUserdata(HTTPConnection* connection);`
*function*

Returns the userdata previously set on the connection.

#### `PDNetErr playdate->network->http->get(HTTPConnection* conn, const char* path, const char* headers, size_t headerlen);`
*function*

Opens the connection to the server if it’s not already open (e.g. from a previous request with keep-alive enabled) and sends a GET request with the given path and additional _headers_ if specified.

#### `PDNetErr playdate->network->http->query(HTTPConnection* conn, const char* method, const char* path, const char* headers, size_t headerlen, const char* body, size_t bodylen);`
*function*

Opens the connection to the server if it’s not already open (e.g. from a previous request with keep-alive enabled) and sends a request with the given method and path, additional _headers_ if specified, and the provided _data_.

#### `PDNetErr playdate->network->http->post(HTTPConnection* conn, const char* path, const char* headers, size_t headerlen, const char* body, size_t bodylen);`
*function*

Equivalent to calling `playdate→network→http→query()` with _method_ equal to `POST`.

#### `PDNetErr playdate->network->http->getError(HTTPConnection* connection);`
*function*

Returns a code for the last error on the connection, or NET_OK if none occurred.

#### `void playdate->network->http->getProgress(HTTPConnection* conn, int* read, int* total);`
*function*

Returns the number of bytes already read from the connection and the total bytes the server plans to send, if known.

#### `int playdate->network->http->getResponseStatus(HTTPConnection* connection);`
*function*

Returns the HTTP status response code, if the request response headers have been received and parsed.

#### `size_t playdate->network->http->getBytesAvailable(HTTPConnection* connection);`
*function*

Returns the number of bytes currently available for reading from the connection.

#### `void playdate->network->http->setReadTimeout(HTTPConnection* connection, int ms);`
*function*

Sets the length of time, in milliseconds, the read() function will wait for incoming data before returning. The default value is 1000, or one second.

#### `void playdate->network->http->setReadBufferSize(HTTPConnection* connection, int bytes);`
*method*

Sets the size of the connection’s read buffer. The default buffer size is 64 KB.

#### `int playdate->network->http->read(HTTPConnection* conn, void* buf, unsigned int buflen);`
*function*

On success, returns up to `length` bytes (limited by the size of the read buffer) from the connection. If `length` is more than the number of bytes available the function will wait for more data up to the length of time set by setReadTimeout() (default one second). If `buf` is NULL, the requested data is discarded. Returns the number of bytes actually read (or discarded), or a (negative) PDNetErr value on error.

#### `void playdate->network->http->close(HTTPConnection* connection);`
*function*

Closes the HTTP connection. The connection may be used again for another request.

##### Callbacks

```
typedef void HTTPHeaderCallback(HTTPConnection* conn, const char* key, const char* value);
typedef void HTTPConnectionCallback(HTTPConnection* connection);
```

#### `void playdate->network->http->setHeaderReceivedCallback(HTTPConnection* connection, HTTPHeaderCallback* header);`
*function*

Sets a callback to be called when the HTTP parser reads a header line from the connection

#### `void playdate->network->http->setHeadersReadCallback(HTTPConnection* connection, HTTPConnectionCallback* header);`
*function*

Sets a function to be called after the connection has parsed the headers from the server response. At this point, getResponseStatus() and getProgress() can be used to query the status and size of the response, and get()/post() can queue another request if `connection:setKeepAlive(true)` was set and the connection is still open.

#### `void playdate->network->http->setResponseCallback(HTTPConnection* connection, HTTPConnectionCallback* header);`
*function*

Sets a function to be called when data is available for reading.

#### `void playdate->network->http->setRequestCompleteCallback(HTTPConnection* connection, HTTPConnectionCallback* header);`
*function*

Sets a function to be called when all data for the request has been received (if the response contained a Content-Length header and the size is known) or the request times out.

#### `void playdate->network->http->setConnectionClosedCallback(HTTPConnection* connection, HTTPConnectionCallback* header);`
*function*

Sets a function to be called when the server has closed the connection.

#### TCP

#### `void playdate->network->tcp->requestAccess(const char* server, int port, bool usessl, const char* purpose, AccessRequestCallback* requestCallback, void* userdata);`
*function*

Before connecting to a server, permission must be given by the user. Unlike in Lua, we don’t have a way to pause the runtime to present the modal dialog, so this function must be explicitly called before calling newConnection(). `server` can be a parent domain of the connections opened, or NULL to request access to any HTTP server. Similarly, if `port` is zero, this requests access to all ports on the target server(s). `purpose` is an optional string displayed in the permissions dialog to explain why the program is requesting access. After the user responds to the request, `requestCallback` is called with the given `userdata` argument. The return value is one of the following:

```
enum accessReply
{
	kAccessAsk,
	kAccessDeny,
	kAccessAllow
};
```

#### `TCPConnection* playdate->network->tcp->newConnection(const char* server, int port, bool usessl);`
*function*

Returns a `playdate.network.tcp` object for connecting to the given server, or NULL if permission has been denied or not yet granted. No connection is attempted until open() is called.

#### `HTTPConnection* playdate->network->tcp->retain(TCPConnection* connection);`
*function*

Adds 1 to the connection’s retain count, so that it won’t be freed when it scopes out of another context. This is used primarily so we can pass a connection created in Lua into C and not have to worry about the Lua wrapper’s lifespan.

#### `void playdate->network->tcp->release(TCPConnection* connection);`
*function*

Releases a previous retain on the connection.

#### `PDNetErr playdate->network->tcp->getError(TCPConnection* connection);`
*function*

Returns a code for the last error on the connection, or NET_OK if none occurred.

#### `void playdate->network->tcp->setConnectTimeout(TCPConnection* connection, int ms);`
*function*

Sets the length of time (in milliseconds) to wait for the connection to the server to be made.

#### `void playdate->network->tcp->setUserdata(TCPConnection* connection, void* userdata);`
*function*

Sets a custom userdata on the connection.

#### `void* playdate->network->tcp->getUserdata(TCPConnection* connection);`
*function*

Returns the userdata previously set on the connection.

#### `PDNetErr playdate->network->tcp->open(TCPConnection* connection, TCPOpenCallback cb, void* ud);`
*function*

```
typedef void TCPOpenCallback(TCPConnection* conn, PDNetErr err, void* ud);
```

Attempts to open the connection to the server. Note that an error may be returned immediately, or in the open callback depending on where it occurs.

#### `PDNetErr playdate->network->tcp->close(TCPConnection* connection);`
*function*

Closes the connection. The connection may be used again for another request.

#### `void playdate->network->tcp->setConnectionClosedCallback(TCPConnection* connection, TCPConnectionCallback* header);`
*function*

```
typedef void TCPConnectionCallback(TCPConnection* connection, PDNetErr err);
```

Sets a callback to be called when the connection is closed.

#### `void playdate->network->tcp->setReadTimeout(TCPConnection* connection, int ms);`
*function*

Sets the length of time, in milliseconds, read() will wait for incoming data before returning. The default value is 1000, or one second.

#### `void playdate->network->tcp->setReadBufferSize(TCPConnection* connection, int bytes);`
*method*

Sets the size of the connection’s read buffer. The default buffer size is 64 KB.

#### `size_t playdate->network->tcp->getBytesAvailable(TCPConnection* connection);`
*function*

Returns the number of bytes currently available for reading from the connection.

#### `int playdate->network->tcp->read(TCPConnection* conn, void *buffer, size_t length);`
*function*

Attempts to read up to `length` bytes from the connection into `buffer`. If `length` is more than the number of bytes available on the connection the function will wait for more data, up to the length of time set by setReadTimeout() (default one second). If `buf` is NULL, the requested data is discarded. Returns the number of bytes actually read (or discarded), or a (negative) PDNetErr value on error.

#### `size_t playdate->network->tcp->write(TCPConnection* conn, const void *buffer, size_t length);`
*function*

Attempts to write up to `length` bytes to the connection. Returns the number of bytes actually written, which may be less than `length`, or a (negative) PDNetErr value on error.

### 7.7. Miscellaneous

#### `void playdate->graphics->clear(LCDColor color);`
*function*

Clears the entire display, filling it with _color_.

Equivalent to `playdate.graphics.clear()` in the Lua API.

#### `void playdate->graphics->setBackgroundColor(LCDColor color);`
*function*

Sets the background color shown when the display is offset or for clearing dirty areas in the sprite system.

Equivalent to `playdate.graphics.setBackgroundColor()` in the Lua API.

#### `void playdate->graphics->display(void);`
*function*

Manually flushes the current frame buffer out to the display. This function is automatically called after each pass through the run loop, so there shouldn’t be any need to call it yourself.

#### `LCDBitmap* playdate->graphics->getDebugBitmap(void);`
*function*

Only valid in the Simulator; function is NULL on device. Returns the debug framebuffer as a bitmap. White pixels drawn in the image are overlaid on the display in 50% transparent red.

#### `uint8_t* playdate->graphics->getDisplayFrame(void);`
*function*

Returns the raw bits in the display buffer, the last completed frame.

#### `LCDBitmap* playdate->graphics->getDisplayBufferBitmap(void);`
*function*

Returns a bitmap containing the contents of the display buffer. The system owns this bitmap—​do not free it!

#### `uint8_t* playdate->graphics->getFrame(void);`
*function*

Returns the current display frame buffer. Rows are 32-bit aligned, so the row stride is 52 bytes, with the extra 2 bytes per row ignored. Bytes are MSB-ordered; i.e., the pixel in column 0 is the 0x80 bit of the first byte of the row.

#### `LCDBitmap* playdate->graphics->copyFrameBufferBitmap(void);`
*function*

Returns a copy the contents of the working frame buffer as a bitmap. The caller is responsible for freeing the returned bitmap with playdate->graphics->freeBitmap().

#### `PDLanguage playdate->system->getLanguage(void);`
*function*

Returns the current language of the system.

```
typedef enum
{
	kPDLanguageEnglish,
	kPDLanguageJapanese,
	kPDLanguageUnknown,
} PDLanguage;
```

#### `void playdate->graphics->markUpdatedRows(int start, int end);`
*function*

After updating pixels in the buffer returned by getFrame(), you must tell the graphics system which rows were updated. This function marks a contiguous range of rows as updated (e.g., markUpdatedRows(0,LCD_ROWS-1) tells the system to update the entire display). Both “start” and “end” are included in the range.

#### `void playdate->graphics->setDrawOffset(int dx, int dy);`
*function*

Offsets the origin point for all drawing calls to _x_, _y_ (can be negative).

This is useful, for example, for centering a "camera" on a sprite that is moving around a world larger than the screen.

Equivalent to `playdate.graphics.setDrawOffset()` in the Lua API.

#### `void playdate->graphics->setColorToPattern(LCDColor* color, LCDBitmap* bitmap, int x, int y);`
*function*

Sets _color_ to an 8 x 8 pattern using the given _bitmap_. _x_, _y_ indicates the top left corner of the 8 x 8 pattern.

#### `void playdate->graphics->setPixel(int x, int y, LCDColor color);`
*function*

Sets the pixel at _(x,y)_ in the current drawing context (by default the screen) to the given _color_. Be aware that setting a pixel at a time is not very efficient: In our testing, more than around 20,000 calls in a tight loop will drop the frame rate below 30 fps.

### 7.8. Video

#### `LCDVideoPlayer playdate->graphics->video->loadVideo(const char* path)`
*function*

Opens the _pdv_ file at _path_ and returns a new video player object for rendering its frames.

#### `void playdate->graphics->video->freePlayer(LCDVideoPlayer* p)`
*function*

Frees the given video player.

#### `int playdate->graphics->video->setContext(LCDVideoPlayer* p, LCDBitmap* context)`
*function*

Sets the rendering destination for the video player to the given bitmap. If the function fails, it returns 0 and sets an error message that can be read via getError().

#### `LCBitmap* playdate->graphics->video->getContext(LCDVideoPlayer* p)`
*function*

Gets the rendering destination for the video player. If no rendering context has been setallocates a context bitmap with the same dimensions as the vieo will be allocated.

#### `void playdate->graphics->video->useScreenContext(LCDVideoPlayer* p)`
*function*

Sets the rendering destination for the video player to the screen.

#### `void playdate->graphics->video->renderFrame(LCDVideoPlayer* p, int n)`
*function*

Renders frame number _n_ into the current context. In case of error, the function returns 0 and sets an error message that can be read via getError().

#### `const char* playdate->graphics->video->getError(LCDVideoPlayer* p)`
*function*

Returns text describing the most recent error.

#### `void playdate->graphics->video->getInfo(LCDVideoPlayer* p, int* outWidth, int* outHeight, float* outFrameRate, int* outFrameCount, int* outCurrentFrame)`
*function*

Retrieves information about the video, by passing in (possibly NULL) value pointers.

### 7.9. Tile Maps

#### `LCDTileMap* playdate->graphics->tilemap->newTilemap(void)`
*function*

Creates a new, empty LCDTileMap object.

#### `void playdate->graphics->tilemap->freeTilemap(LCDTileMap* tilemap)`
*function*

Frees an LCDTileMap object previously allocated with `playdate→graphics→tilemap→newTilemap()`.

#### `void playdate->graphics->tilemap->setImageTable(LCDTileMap* tilemap, LCDBitmapTable* table)`
*function*

Sets the image table to use for the tilemap’s tiles.

#### `LCDBitmapTable* playdate->graphics->tilemap->getImageTable(LCDTileMap* tilemap)`
*function*

Returns the LCDBitmapTable used for the tilemap’s tiles.

#### `void playdate->graphics->tilemap->setSize(LCDTileMap* tilemap, int tilesWide, int tilesHigh)`
*function*

Sets the tilemap’s width and height, in number of tiles.

#### `void playdate->graphics->tilemap->getSize(LCDTileMap* tilemap, int* outwidth, int* outheight)`
*function*

Returns the size of the tile map, in tiles.

#### `void playdate->graphics->tilemap->getPixelSize(LCDTileMap* tilemap, uint32_t* outwidth, uint32_t* outheight)`
*function*

Returns the size of the tilemap in pixels; that is, the size of the tile image multiplied by the number of rows and columns in the tilemap.

#### `void playdate->graphics->tilemap->setTiles(LCDTileMap* tilemap, uint16_t* indexes, int count, int rowwidth)`
*function*

Sets the tilemap’s width to _rowwidth_ and height to _count/rowwidth_ (_count_ must be evenly divisible by _rowwidth_), then sets the tiles' indexes to the given list.

#### `void playdate->graphics->tilemap->setTileAtPosition(LCDTileMap* tilemap, int x, int y, uint16_t idx)`
*function*

Sets the index of the tile at tilemap position (_x_, _y_). _index_ is the (0-based) index of the cell in the tilemap’s image table.

#### `int playdate->graphics->tilemap->getTileAtPosition(LCDTileMap* tilemap, int x, int y)`
*function*

Returns the image index of the tile at the given _x_ and _y_ coordinate. If _x_ or _y_ is out of bounds, returns -1.

#### `void playdate->graphics->tilemap->drawAtPoint(LCDTileMap* m, float x, float y, LCDBitmapDrawMode mode)`
*function*

Draws the tile map at coordinate (_x_, _y_).

### 7.10. Input

#### `void playdate->system->setPeripheralsEnabled(PDPeripherals mask)`
*function*

By default, the accelerometer is disabled to save (a small amount of) power. To use a peripheral, it must first be enabled via this function. Accelerometer data is not available until the next update cycle after it’s enabled.

```
kNone
kAccelerometer
```

#### Accelerometer

#### `void playdate->system->getAccelerometer(float* outx, float* outy, float* outz)`
*function*

Returns the last-read accelerometer data.

#### Buttons

#### `void playdate->system->getButtonState(PDButtons* current, PDButtons* pushed, PDButtons* released)`
*function*

Sets the value pointed to by _current_ to a bitmask indicating which buttons are currently down. _pushed_ and _released_ reflect which buttons were pushed or released over the previous update cycle—at the nominal frame rate of 50 ms, fast button presses can be missed if you just poll the instantaneous state.

```
kButtonLeft
kButtonRight
kButtonUp
kButtonDown
kButtonB
kButtonA
```

#### `void playdate->system->setButtonCallback(PDButtonCallbackFunction* cb, void* userdata, int queuesize)`
*function*

As an alternative to polling for button presses using `getButtonState()`, this function allows a callback function to be set. The function is called for each button up/down event (possibly multiple events on the same button) that occurred during the previous update cycle. At the default 30 FPS, a queue size of 5 should be adequate. At lower frame rates/longer frame times, the queue size should be extended until all button presses are caught. The function should return 0 on success or a non-zero value to signal an error.

```
typedef int PDButtonCallbackFunction(PDButtons button, int down, uint32_t when, void* userdata);
```

#### Crank

#### `float playdate->system->getCrankAngle(void)`
*function*

Returns the current position of the crank, in the range 0-360. Zero is pointing up, and the value increases as the crank moves clockwise, as viewed from the right side of the device.

#### `float playdate->system->getCrankChange(void)`
*function*

Returns the angle change of the crank since the last time this function was called. Negative values are anti-clockwise.

#### `int playdate->system->isCrankDocked(void)`
*function*

Returns 1 or 0 indicating whether or not the crank is folded into the unit.

### 7.11. Device Auto Lock

As of 1.9.1, the device will automatically lock if the user doesn’t press any buttons or use the crank for more than 3 minutes. In order for games that expect longer periods without interaction to continue to function, it is possible to manually disable the auto lock feature.
Note that when disabling the timeout, developers should take care to re-enable the timeout when appropiate.

#### `void playdate->system->setAutoLockDisabled(int disable)`
*function*

Disables or enables the 3 minute auto lock feature. When called, the timer is reset to 3 minutes.

### 7.12. System Sounds

0.12 adds sound effects for various system events, such as the menu opening or closing, USB cable plugged or unplugged, and the crank docked or undocked. Since games can receive notification of the crank docking and undocking, and may incorporate this into the game, we’ve provided a function for muting the default sounds for these events:

#### `int playdate->system->setCrankSoundsDisabled(int disable)`
*function*

The function returns the previous value for this setting.

### 7.13. JSON

#### Decoding

#### `int playdate->json->decode(struct json_decoder* decoder, json_reader reader, json_value* outval);`
*function*

Equivalent to `playdate.json.decode()` in the Lua API.

#### `int playdate->json->decodeString(struct json_decoder* decoder, const char* jsonString, json_value* outval);`
*function*

Decodes a JSON file or string with the given _decoder_. An instance of json_decoder must implement _decodeError_. The remaining functions are optional although you’ll probably want to implement at least _didDecodeTableValue_ and _didDecodeArrayValue_. The _outval_ pointer, if set, contains the value retured from the top-level _didDecodeSublist_ callback.

```
typedef struct json_decoder
{
	void (*decodeError)(json_decoder* decoder, const char* error, int linenum);
	void (*willDecodeSublist)(json_decoder* decoder, const char* name, json_value_type type);
	int (*shouldDecodeTableValueForKey)(json_decoder* decoder, const char* key);
	void (*didDecodeTableValue)(json_decoder* decoder, const char* key, json_value value);
	int (*shouldDecodeArrayValueAtIndex)(json_decoder* decoder, int pos);
	void (*didDecodeArrayValue)(json_decoder* decoder, int pos, json_value value);
	void* (*didDecodeSublist)(json_decoder* decoder, const char* name, json_value_type type);
	void* userdata;
	int returnString;
	const char* path;
} json_decoder;
```

- _decodeError_: Called when the decoder encounters an error.
- _willDecodeSublist_: Called before attempting to decode a JSON object or array.
- _didDecodeSublist_: Called after successfully decoding a JSON object or array. The returned value is passed to the corresponding _didDecodeTableValue()_ or _didDecodeArrayValue()_ callback one level up, or the calling decode() or decodeString() function if the list is the top-level json object
- _shouldDecodeTableValueForKey_: Called before decoding a _key_/_value_ pair from an object. Return 1 to proceed with decoding or return 0 to skip this pair.
- _shouldDecodeArrayValueAtIndex_: Called before decoding the _value_ at _pos_ from an array (note that _pos_ is base 1 not 0). Return 1 to proceed with decoding or return 0 to skip this index.
- _didDecodeTableValue_: Called after successfully decoding a _key_/_value_ pair from an object.
- _didDecodeArrayValue_: Called after successfully decoding the _value_ at _pos_ from an array.
- _userdata_: A storage slot for the API client
- _returnString_: If set in _willDecodeSublist_, the sublist is returned as a string instead of parsed
- _path_: The current path in the parse tree. The root scope is named `_root`, but this is not included in the path when parsing the root’s children

Note that the decoder saves and restores the decoder struct at each level of the tree. This lets you add unique handlers for different sections of the json structure:

```
void myParser_WillDecodeSublist(json_decoder* decoder, const char* name, json_value_type type)
{
	if ( strcmp(name, "widget") == 0 )
	{
		Widget* widget = pd_malloc(sizeof(Widget));
		decoder->userdata = widget;
		decoder->didDecodeTableValue = setWidgetValue;
		decoder->didDecodeSublist = finishWidget;
	}
}
```

```
void setWidgetValue(json_decoder* decoder, const char* key, json_value value)
{
	Widget* widget = decoder->userdata;
	if ( strcmp(key, "floops") == 0 )
		widget.floops = json_floatValue(value);
	// ...
}
```

```
void* finishWidget(json_decoder* decoder, const char* name, json_value_type type)
{
	widgetCompleted(decoder->userdata); // send to external function
	return decoder->userdata; // or return the widget in didDecodeTableValue()'s value.data.tableval field
}
```

After `finishWidget()` is called and the parser exits the scope, the previous decoder functions are restored.

```
typedef enum
{
	kJSONNull,
	kJSONTrue,
	kJSONFalse,
	kJSONInteger,
	kJSONFloat,
	kJSONString,
	kJSONArray,
	kJSONTable
} json_value_type;
```

```
typedef struct
{
	char type;
	union
	{
		int intval;
		float floatval;
		char* stringval;
		void* arrayval;
		void* tableval;
	} data;
} json_value;
```

#### `int json_intValue(json_value value);`
*function*

#### `float json_floatValue(json_value value);`
*function*

#### `int json_boolValue(json_value value);`
*function*

#### `char* json_stringValue(json_value value);`
*function*

Note that a whole number encoded to JSON as a float might be decoded as an int. The above convenience functions can be used to convert a _json_value_ to the required type.

```
typedef struct
{
	int (*read)(void* readud, uint8_t* buf, int bufsize); // fill buffer, return bytes written or 0 on end of data
	void* userdata;
} json_reader;
```

json_reader’s _read_ member provides data to the decoder. It should return 0 when it is done reading. Here’s an example implementation:

```
int readfile(void* readud, uint8_t* buf, int bufsize) {
	return playdate->file->read((SDFile*)readud, buf, bufsize);
}
```

```
SDFile* file = pd->file->open("data.json", kFileRead);
pd->json->decode(&decoder, (json_reader){ .read = readfile, .userdata = file }, NULL);
```

#### Encoding

#### `void playdate->json->initEncoder(json_encoder* encoder, writeFunc* write, void* userdata, int pretty);`
*function*

Populates the given json_encoder _encoder_ with the functions necessary to encode arbitrary data into a JSON string. _userdata_ is passed as the first argument of the given writeFunc _write_. When _pretty_ is 1 the string is written with human-readable formatting.

```
typedef struct json_encoder
{
	void (*startArray)(struct json_encoder* encoder);
	void (*addArrayMember)(struct json_encoder* encoder);
	void (*endArray)(struct json_encoder* encoder);
	void (*startTable)(struct json_encoder* encoder);
	void (*addTableMember)(struct json_encoder* encoder, const char* name, int len);
	void (*endTable)(struct json_encoder* encoder);
	void (*writeNull)(struct json_encoder* encoder);
	void (*writeFalse)(struct json_encoder* encoder);
	void (*writeTrue)(struct json_encoder* encoder);
	void (*writeInt)(struct json_encoder* encoder, int num);
	void (*writeDouble)(struct json_encoder* encoder, double num);
	void (*writeString)(struct json_encoder* encoder, const char* str, int len);
} json_encoder;
```

Note that the encoder doesn’t perform any validation. It is up to the caller to ensure they are generating valid JSON.

- _startArray_: Opens a new JavaScript Array.
- _addArrayMember_: Creates a new index in the current JavaScript Array.
- _endArray_: Closes the current JavaScript Array.
- _startTable_: Opens a new JavaScript Object.
- _addTableMember_: Creates a new property in the current JavaScript Object.
- _endTable_: Closes the current JavaScript Object.
- _writeNull_: Writes the JavaScript primitive null.
- _writeFalse_: Writes the JavaScript boolean value false.
- _writeTrue_: Writes the JavaScript boolean value true.
- _writeInt_: Writes _num_ as a JavaScript number.
- _writeDouble_: Writes _num_ as a JavaScript number.
- _writeString_: Writes _str_ of length _len_ as a JavaScript string literal.

```
typedef void (writeFunc)(void* userdata, const char* str, int len);
```

Here’s an example _writeFunc_ implementation using playdate->file->write() to write the JSON string to a file:

```
void writefile(void* userdata, const char* str, int len) {
	playdate->file->write((SDFile*)userdata, str, len);
}
```

### 7.14. Lua

#### Adding functions or tables

#### `int playdate->lua->addFunction(lua_CFunction f, const char* name, const char** outErr);`
*function*

Adds the Lua function _f_ to the Lua runtime, with name _name_. (_name_ can be a table path using dots, e.g. if name = “mycode.myDrawingFunction” adds the function “myDrawingFunction” to the global table “myCode”.) Returns 1 on success or 0 with an error message in _outErr_.

```
typedef int (*lua_CFunction) (lua_State *L);
```

A _lua_CFunction_ should return the number of return values it has pushed onto the stack. Returns 1 on success or 0 with an error message in _outErr_. See Returning values to Lua.

#### `void playdate->lua->registerClass_deprecated(const luaL_Reg* reg, const char* name, const char** outErr);`
*function*

Adds the function list _reg_ to the Lua runtime, with the class name _name_. As above, _name_ can be a table path. The list is terminated with a {NULL, NULL} entry.

#### `int playdate->lua->registerClass(const char* name, const lua_reg* reg, const lua_val* vals, int isstatic, const char** outErr);`
*function*

Creates a new "class" (i.e., a Lua metatable containing functions) with the given name and adds the given functions and constants to it. If the table is simply a list of functions that won’t be used as a metatable, _isstatic_ should be set to 1 to create a plain table instead of a metatable. Please see `C_API/Examples/Array` for an example of how to use `registerClass` to create a Lua table-like object from C.

```
typedef struct lua_reg
{
	const char *name;
	lua_CFunction func;
} lua_reg;
```

```
typedef struct lua_val
{
	const char *name;
	enum { kInt, kFloat, kStr } type;
	union
	{
		unsigned int intval;
		float floatval;
		const char* strval;
	} v;
} luaL_Val;
```

#### `int playdate->lua->indexMetatable(void);`
*function*

If a class includes an `__index` function, it should call this first to check if the indexed variable exists in the metatable. If the indexMetatable() call returns 1, it has located the variable and put it on the stack, and the `__index` function should return 1 to indicate a value was found. If indexMetatable() doesn’t find a value, the `__index` function can then do its custom getter magic.

#### `void playdate->lua->start(void);`
*function*

Starts the run loop back up.

#### `void playdate->lua->stop(void);`
*function*

Stops the run loop.

#### Getting values from Lua

The following functions are called from within a Lua function implementation to retrieve the function arguments and set the return value(s):

#### `enum LuaType playdate->lua->getArgType(int pos, const char** outClass);`
*function*

Returns the type of the variable at stack position _pos_. If the type is _kTypeObject_ and _outClass_ is non-NULL, it returns the name of the object’s metatable.

```
enum LuaType
{
	kTypeNil,
	kTypeBool,
	kTypeInt,
	kTypeFloat,
	kTypeString,
	kTypeTable,
	kTypeFunction,
	kTypeThread,
	kTypeObject
};
```

#### `int playdate->lua->getArgCount(void);`
*function*

Returns the number of arguments passed to the function.

#### `int playdate->lua->argIsNil(int pos);`
*function*

Returns 1 if the argument at the given position _pos_ is nil.

#### `int playdate->lua->getArgBool(int pos);`
*function*

Returns one if the argument at position _pos_ is true, zero if not.

#### `float playdate->lua->getArgFloat(int pos);`
*function*

Returns the argument at position _pos_ as a float.

#### `int playdate->lua->getArgInt(int pos);`
*function*

Returns the argument at position _pos_ as an int.

#### `const char* playdate->lua->getArgString(int pos);`
*function*

Returns the argument at position _pos_ as a string.

#### `LCDSprite* playdate->lua->getSprite(int pos);`
*function*

Returns the argument at position _pos_ as an LCDSprite.

#### `const char* playdate->lua->getArgBytes(int pos, size_t* outlen);`
*function*

Returns the argument at position _pos_ as a string and sets _outlen_ to its length.

#### `LCDBitmap* playdate->lua->getBitmap(int pos);`
*function*

Returns the argument at position _pos_ as an LCDBitmap.

#### Returning values to Lua

If a function needs to return data to the caller it must return the number of return values pushed onto the stack.

#### `void playdate->lua->pushBool(int val);`
*function*

Pushes the int _val_ onto the stack.

#### `void playdate->lua->pushFloat(float val);`
*function*

Pushes the float _val_ onto the stack.

#### `void playdate->lua->pushInt(int val);`
*function*

Pushes the int _val_ onto the stack.

#### `void playdate->lua->pushNil(void);`
*function*

Pushes nil onto the stack.

#### `void playdate->lua->pushString(char* str);`
*function*

Pushes the string _str_ onto the stack.

#### `void playdate->lua->pushBytes(char* str, size_t len);`
*function*

Like _pushString()_, but pushes an arbitrary byte array to the stack, ignoring \0 characters.

#### `void playdate->lua->pushFunction(lua_CFunction f);`
*function*

Pushes a lua_CFunction onto the stack.

#### `void playdate->lua->pushBitmap(LCDBitmap* bitmap);`
*function*

Pushes the LCDBitmap _bitmap_ onto the stack.

#### `void playdate->lua->pushSprite(LCDSprite* sprite);`
*function*

Pushes the LCDSprite _sprite_ onto the stack.

#### Passing custom objects between C and Lua

#### `LuaUDObject* playdate->lua->pushObject(void* obj, char* type, int nValues);`
*function*

Pushes the given custom object _obj_ onto the stack and returns a pointer to the opaque LuaUDObject. _type_ must match the class name used in playdate->lua->registerClass(). _nValues_ is the number of slots to allocate for Lua values (see set/getObjectValue()).

#### `void* playdate->lua->getArgObject(int pos, char* type, LuaUDObject** outud);`
*function*

Checks the object type of the argument at position _pos_ and returns a pointer to it if it’s the correct type. Optionally sets _outud_ to a pointer to the opaque LuaUDObject for the given stack.

#### `LuaUDObject* playdate->lua->retainObject(LuaUDObject* obj);`
*function*

Retains the opaque LuaUDObject _obj_ and returns same.

#### `void playdate->lua->releaseObject(LuaUDObject* obj);`
*function*

Releases the opaque LuaUDObject _obj_.

#### `void playdate->lua->setUserValue(LuaUDObject* obj, int slot);`
*function*

Sets the value of object _obj_'s uservalue slot number _slot_ (starting at 1, not zero) to the value at the top of the stack.

#### `int playdate->lua->getUserValue(LuaUDObject* obj, int slot);`
*function*

Copies the value at _obj_'s given uservalue _slot_ to the top of the stack and returns its stack position.

#### Calling Lua from C

#### `int playdate->lua->callFunction(const char* name, int nargs, const char** outerr);`
*function*

Calls the Lua function _name_ and and indicates that _nargs_ number of arguments have already been pushed to the stack for the function to use. _name_ can be a table path using dots, e.g. “playdate.apiVersion”. Returns 1 on success; on failure, returns 0 and puts an error message into the `outerr` pointer, if it’s set. Calling Lua from C is slow, so use sparingly.

### 7.15. Sprites

#### `LCDSprite* playdate->sprite->newSprite(void);`
*function*

Allocates and returns a new LCDSprite.

#### `LCDSprite* playdate->sprite->copy(LCDSprite *sprite);`
*function*

Allocates and returns a copy of the given _sprite_.

#### `void playdate->sprite->freeSprite(LCDSprite *sprite);`
*function*

Frees the given _sprite_.

#### Properties

#### `void playdate->sprite->setBounds(LCDSprite *sprite, PDRect bounds);`
*function*

Sets the bounds of the given _sprite_ with _bounds_.

#### `PDRect playdate->sprite->getBounds(LCDSprite *sprite);`
*function*

Returns the bounds of the given _sprite_ as an PDRect;

#### `void playdate->sprite->moveTo(LCDSprite *sprite, float x, float y);`
*function*

Moves the given _sprite_ to _x_, _y_ and resets its bounds based on the bitmap dimensions and center.

#### `void playdate->sprite->moveBy(LCDSprite *sprite, float dx, float dy);`
*function*

Moves the given _sprite_ to by offsetting its current position by _dx_, _dy_.

#### `void playdate->sprite->getPosition(LCDSprite *sprite, float *x, float *y);`
*function*

Sets _x_ and _y_ to the current position of _sprite_.

#### `void playdate->sprite->setCenter(LCDSprite *sprite, float x, float y);`
*function*

Sets the sprite’s drawing center as a fraction (ranging from 0.0 to 1.0) of the height and width. Default is 0.5, 0.5 (the center of the sprite). This means that when you call sprite→moveTo(sprite, x, y), the center of your sprite will be positioned at _x_, _y_. If you want x and y to represent the upper left corner of your sprite, specify the center as 0, 0.

#### `void playdate->sprite->getCenter(LCDSprite *sprite, float *outx, float *outy);`
*function*

Sets the values in `outx` and `outy` to the sprite’s drawing center as a fraction (ranging from 0.0 to 1.0) of the height and width.

#### `void playdate->sprite->setImage(LCDSprite *sprite, LCDBitmap *image, LCDBitmapFlip flip);`
*function*

Sets the given _sprite_'s image to the given _bitmap_.

#### `LCDBitmap* playdate->sprite->getImage(LCDSprite *sprite);`
*function*

Returns the LCDBitmap currently assigned to the given _sprite_.

#### `void playdate->sprite->setTilemap(LCDSprite* sprite, LCDTileMap* tilemap);`
*function*

Sets the given _sprite_'s image to the given tilemap_.

#### `LCDTileMap* playdate->sprite->getTilemap(LCDSprite *sprite);`
*function*

Returns the LCDTileMap currently assigned to the given _sprite_.

#### `void playdate->sprite->setSize(LCDSprite *s, float width, float height);`
*function*

Sets the size. The size is used to set the sprite’s bounds when calling moveTo().

#### `void playdate->sprite->setZIndex(LCDSprite *sprite, int16_t zIndex);`
*function*

Sets the Z order of the given _sprite_. Higher Z sprites are drawn on top of those with lower Z order.

#### `int16_t playdate->sprite->getZIndex(LCDSprite *sprite);`
*function*

Returns the Z index of the given _sprite_.

#### `void playdate->sprite->setTag(LCDSprite *sprite, uint8_t tag);`
*function*

Sets the tag of the given _sprite_. This can be useful for identifying sprites or types of sprites when using the collision API.

#### `uint8_t playdate->sprite->getTag(LCDSprite *sprite);`
*function*

Returns the tag of the given _sprite_.

#### `void playdate->sprite->setDrawMode(LCDSprite *sprite, LCDBitmapDrawMode mode);`
*function*

Sets the mode for drawing the sprite’s bitmap.

#### `void playdate->sprite->setImageFlip(LCDSprite *sprite, LCDBitmapFlip flip);`
*function*

Flips the bitmap.

#### `LCDBitmapFlip playdate->sprite->getImageFlip(LCDSprite *sprite);`
*function*

Returns the flip setting of the sprite’s bitmap.

#### `void playdate->sprite->setStencilImage(LCDSprite *sprite, LCDBitmap* stencil, int tile);`
*function*

Specifies a stencil image to be set on the frame buffer before the sprite is drawn. While the stencil is active, the sprite pixels will be drawn where the stencil is white and nothing drawn where the stencil is black. Note that the stencil is attached to the frame buffer (i.e., the screen), not the sprite—it does not move along with the sprite. If _stencil_ is NULL, the stencil is cleared. If _tile_ is set, the stencil will be tiled. Tiled stencils must have width evenly divisible by 32.

#### `void playdate->sprite->setStencil(LCDSprite *sprite, LCDBitmap* stencil);`
*function*

Specifies a stencil image to be set on the frame buffer before the sprite is drawn.

#### `void playdate->sprite->setStencilPattern(LCDSprite* sprite, uint8_t pattern[8]);`
*function*

Sets the sprite’s stencil to the given pattern.

#### `void playdate->sprite->clearStencil(LCDSprite *sprite);`
*function*

Clears the sprite’s stencil.

#### `void playdate->sprite->setClipRect(LCDSprite *sprite, LCDRect clipRect);`
*function*

Sets the clipping rectangle for sprite drawing.

#### `void playdate->sprite->clearClipRect(LCDSprite *sprite);`
*function*

Clears the sprite’s clipping rectangle.

#### `void playdate->sprite->setClipRectsInRange(LCDRect clipRect, int startZ, int endZ);`
*function*

Sets the clipping rectangle for _all_ sprites with a Z index within _startZ_ and _endZ_ inclusive.

#### `void playdate->sprite->clearClipRectsInRange(int startZ, int endZ);`
*function*

Clears the clipping rectangle for _all_ sprites with a Z index within _startZ_ and _endZ_ inclusive.

#### `void playdate->sprite->setUpdatesEnabled(LCDSprite *sprite, int flag);`
*function*

Set the updatesEnabled flag of the given _sprite_ (determines whether the sprite has its update function called). One is true, 0 is false.

#### `int playdate->sprite->updatesEnabled(LCDSprite *sprite);`
*function*

Get the updatesEnabled flag of the given _sprite_.

#### `void playdate->sprite->setVisible(LCDSprite *sprite, int flag);`
*function*

Set the visible flag of the given _sprite_ (determines whether the sprite has its draw function called). One is true, 0 is false.

#### `int playdate->sprite->isVisible(LCDSprite *sprite);`
*function*

Get the visible flag of the given _sprite_.

#### `void playdate->sprite->setOpaque(LCDSprite *sprite, int flag);`
*function*

Marking a sprite opaque tells the sprite system that it doesn’t need to draw anything underneath the sprite, since it will be overdrawn anyway. If you set an image without a mask/alpha channel on the sprite, it automatically sets the opaque flag.

#### `void playdate->sprite->setAlwaysRedraw(int flag);`
*function*

When _flag_ is set to 1, this causes all sprites to draw each frame, whether or not they have been marked dirty. This may speed up the performance of your game if the system’s dirty rect tracking is taking up too much time - for example if there are many sprites moving around on screen at once.

#### `void playdate->sprite->markDirty(LCDSprite *sprite);`
*function*

Forces the given _sprite_ to redraw.

#### `void playdate->sprite->addDirtyRect(LCDRect dirtyRect);`
*function*

Marks the given _dirtyRect_ (in screen coordinates) as needing a redraw. Graphics drawing functions now call this automatically, adding their drawn areas to the sprite’s dirty list, so there’s usually no need to call this manually.

#### `void playdate->sprite->setIgnoresDrawOffset(LCDSprite *sprite, int flag);`
*function*

When _flag_ is set to 1, the _sprite_ will draw in screen coordinates, ignoring the currently-set drawOffset.

This only affects drawing, and should not be used on sprites being used for collisions, which will still happen in world-space.

#### `void playdate->sprite->setUpdateFunction(LCDSprite *sprite, LCDSpriteUpdateFunction *func);`
*function*

Sets the update function for the given _sprite_.

```
typedef void LCDSpriteUpdateFunction(LCDSprite* sprite);
```

#### `void playdate->sprite->setDrawFunction(LCDSprite *sprite, LCDSpriteDrawFunction *func);`
*function*

Sets the draw function for the given _sprite_. Note that the callback is only called when the sprite is on screen and has a size specified via playdate→sprite→setSize() or playdate→sprite→setBounds().

```
typedef void LCDSpriteDrawFunction(LCDSprite* sprite, PDRect bounds, PDRect drawrect);
```

If the sprite doesn’t have an image, the sprite’s draw function is called as needed to update the display. _bounds_ is the bounds of hte given _sprite_. _frame_ is the raw bitmap data of the current frame buffer. _drawRect_ is the current dirty rect being updated by the display list.

#### `void playdate->sprite->setUserdata(LCDSprite *sprite, void* userdata);`
*function*

#### `void* playdate->sprite->getUserdata(LCDSprite *sprite);`
*function*

Sets and gets the sprite’s userdata, an arbitrary pointer used for associating the sprite with other data.

#### Display List

#### `void playdate->sprite->addSprite(LCDSprite *sprite);`
*function*

Adds the given _sprite_ to the display list, so that it is drawn in the current scene.

#### `void playdate->sprite->removeSprite(LCDSprite *sprite);`
*function*

Removes the given _sprite_ from the display list.

#### `void playdate->sprite->removeSprites(LCDSprite **sprites, int count);`
*function*

Removes the given _count_ sized array of _sprites_ from the display list.

#### `void playdate->sprite->removeAllSprites(void);`
*function*

Removes all sprites from the display list.

#### `int playdate->sprite->getSpriteCount(void);`
*function*

Returns the total number of sprites in the display list.

#### `void playdate->sprite->drawSprites(void);`
*function*

Draws every sprite in the display list.

#### `void playdate->sprite->updateAndDrawSprites(void);`
*function*

Updates and draws every sprite in the display list.

#### Collisions

Note that the caller is responsible for freeing any arrays returned by these collision methods.

#### `void playdate->sprite->resetCollisionWorld(void);`
*function*

Frees and reallocates internal collision data, resetting everything to its default state.

#### `void playdate->sprite->setCollisionsEnabled(LCDSprite *sprite, int flag);`
*function*

Set the collisionsEnabled flag of the given _sprite_ (along with the collideRect, this determines whether the sprite participates in collisions). One is true, 0 is false. Set to 1 by default.

#### `int playdate->sprite->collisionsEnabled(LCDSprite *sprite);`
*function*

Get the collisionsEnabled flag of the given _sprite_.

#### `void playdate->sprite->setCollideRect(LCDSprite *sprite, PDRect collideRect);`
*function*

Marks the area of the given _sprite_, relative to its bounds, to be checked for collisions with other sprites' collide rects.

#### `PDRect playdate->sprite->getCollideRect(LCDSprite *sprite);`
*function*

Returns the given _sprite_’s collide rect.

#### `void playdate->sprite->clearCollideRect(LCDSprite *sprite);`
*function*

Clears the given _sprite_’s collide rect.

#### `void playdate->sprite->setCollisionResponseFunction(LCDSprite *sprite, LCDSpriteCollisionFilterProc *func);`
*function*

Set a callback that returns a SpriteCollisionResponseType for a collision between _sprite_ and _other_.

```
typedef SpriteCollisionResponseType LCDSpriteCollisionFilterProc(LCDSprite* sprite, LCDSprite* other);
```

#### `SpriteCollisionInfo* playdate->sprite->checkCollisions(LCDSprite *sprite, float goalX, float goalY, float *actualX, float *actualY, int *len);`
*function*

Returns the same values as playdate->sprite->moveWithCollisions() but does not actually move the sprite. The caller is responsible for freeing the returned array.

#### `SpriteCollisionInfo* playdate->sprite->moveWithCollisions(LCDSprite *sprite, float goalX, float goalY, float *actualX, float *actualY, int *len);`
*function*

Moves the given _sprite_ towards _goalX_, _goalY_ taking collisions into account and returns an array of SpriteCollisionInfo. _len_ is set to the size of the array and _actualX_, _actualY_ are set to the sprite’s position after collisions. If no collisions occurred, this will be the same as _goalX_, _goalY_. The caller is responsible for freeing the returned array.

Note that SpriteCollisionInfo is a struct so you should grab a pointer when accessing each one: `SpriteCollisionInfo *info = &results[i];`.

```
struct SpriteCollisionInfo
{
	LCDSprite *sprite;
	LCDSprite *other;
	SpriteCollisionResponseType responseType;
	uint8_t overlaps;
	float ti;
	CollisionPoint move;
	CollisionVector normal;
	CollisionPoint touch;
	PDRect spriteRect;
	PDRect otherRect;
};
```

- _sprite_: The sprite being moved.
- _other_: The sprite colliding with the sprite being moved.
- _type_: The result of collisionResponse (see SpriteCollisionResponseType below).
- _overlaps_: One if the sprite was overlapping other when the collision started. Zero if it didn’t overlap but tunneled through other.
- _ti_: A number between 0 and 1 indicating how far along the movement to the goal the collision occurred.
- _move_: The difference between the original coordinates and the actual ones when the collision happened (see CollisionPoint below).
- _normal_: The collision normal; usually -1, 0, or 1 in x and y. Use this value to determine things like if your character is touching the ground (see CollisionVector below).
- _touch_: The coordinates where the sprite started touching other.
- _spriteRect_: The rectangle the sprite occupied when the touch happened.
- _otherRect_: The rectangle other occupied when the touch happened.

```
typedef enum {
	kSpriteCollisionTypeSlide,
	kSpriteCollisionTypeFreeze,
	kSpriteCollisionTypeOverlap,
	kSpriteCollisionTypeBounce
} SpriteCollisionResponseType;
```

- _kSpriteCollisionTypeSlide_: Use for collisions that should slide over other objects, like Super Mario does over a platform or the ground.
- _kSpriteCollisionTypeFreeze_: Use for collisions where the sprite should stop moving as soon as it collides with other, such as an arrow hitting a wall.
- _kSpriteCollisionTypeOverlap_: Use for collisions in which you want to know about the collision but it should not impact the movement of the sprite, such as when collecting a coin.
- _kSpriteCollisionTypeBounce_: Use when the sprite should move away from other, like the ball in Pong or Arkanoid.

```
typedef struct {
	float x;
	float y;
} CollisionPoint;
```

```
typedef struct {
	int x;
	int y;
} CollisionVector;
```

#### `LCDSprite** playdate->sprite->querySpritesAtPoint(float x, float y, int *len);`
*function*

Returns an array of all sprites with collision rects containing the point at _x_, _y_. _len_ is set to the size of the array. The caller is responsible for freeing the returned array.

#### `LCDSprite** playdate->sprite->querySpritesInRect(float x, float y, float width, float height, int *len);`
*function*

Returns an array of all sprites with collision rects that intersect the _width_ by _height_ rect at _x_, _y_. _len_ is set to the size of the array. The caller is responsible for freeing the returned array.

#### `LCDSprite** playdate->sprite->querySpritesAlongLine(float x1, float y1, float x2, float y2, int *len);`
*function*

Returns an array of all sprites with collision rects that intersect the line connecting _x1_, _y1_ and _x2_, _y2_. _len_ is set to the size of the array. The caller is responsible for freeing the returned array.

#### `SpriteQueryInfo* playdate->sprite->querySpriteInfoAlongLine(float x1, float y1, float x2, float y2, int *len);`
*function*

Returns an array of SpriteQueryInfo for all sprites with collision rects that intersect the line connecting _x1_, _y1_ and _x2_, _y2_. _len_ is set to the size of the array. If you don’t need this information, use querySpritesAlongLine() as it will be faster. The caller is responsible for freeing the returned array.

Note that SpriteQueryInfo is a struct so you should grab a pointer when accessing each one: `SpriteQueryInfo *info = &results[i];`.

```
struct SpriteQueryInfo
{
	LCDSprite *sprite;
	float ti1;
	float ti2;
	CollisionPoint entryPoint;
	CollisionPoint exitPoint;
};
```

- _sprite_: The sprite being intersected by the segment.
- _ti1_ & _ti2_: Numbers between 0 and 1 which indicate how far from the starting point of the line segment the collision happened. _ti1_ is relative to the entry point, _ti2_ is relative to the exit point.
- _entryPoint_: The coordinates of the first intersection between sprite and the line segment (see CollisionPoint above).
- _exitPoint_: The coordinates of the second intersection between sprite and the line segment (see CollisionPoint above).

#### `LCDSprite** playdate->sprite->overlappingSprites(LCDSprite *sprite, int *len);`
*function*

Returns an array of sprites that have collide rects that are currently overlapping the given _sprite_’s collide rect. _len_ is set to the size of the array. The caller is responsible for freeing the returned array.

#### `LCDSprite** playdate->sprite->allOverlappingSprites(int *len);`
*function*

Returns an array of all sprites that have collide rects that are currently overlapping. Each consecutive pair of sprites is overlapping (eg. 0 & 1 overlap, 2 & 3 overlap, etc). _len_ is set to the size of the array. The caller is responsible for freeing the returned array.

## 8. Performance Considerations

### 8.1. Floating point Math operations

The Cortex-M7 processor used in the Playdate has support for _single_ precision floating point operations (ie. the `float` type), but **not** for _double_ precision operations (ie. the `double` type).

When using `double` precision values, the compiler will emit code that emulates double-precision floating point calcuations, rather than using the specialized hardware for single-precision floating point calculations. This is extremely slow in comparison, and will come at a large cost of performance.

One small (but important) thing to keep in mind is that constant floating point values, like `3.14` are implicitly `double` typed values at compile time. Ensure that any constant values are floats by adding the `f` suffix: `3.14f`, `1.f`, and so on.

The C standard library has variants on its math functions with operate on either `double` or `float` values. When using these, make sure that you are using the `float` variant. For example, ensure you are using `fabsf()` not `fabs()`, and `powf()` rather thatn `pow()`, and so on.

Some compiler flags can be used to make these mistakes obvious or easier to deal with:

- `-Wdouble-promotion`: Warns whenever a `float` is implicitly being converted to double.
- `-fsingle-precision-constant`: All real constants will be `float` rather than `double`, ie. `1.0` will be the same as `1.0f`.

## 9. Getting Help

### 9.1. Where can I download the SDK?

Head to the [Playdate Developer](https://play.date/dev/) page to download the latest SDK.

### 9.2. Where do I go if I have questions about the SDK?

You can find the SDK documentation for Lua [here](https://sdk.play.date/inside-playdate) and C [here](https://sdk.play.date/inside-playdate-with-c) . If you’re interested in seeing the Playdate SDK in action, check out our [Twitch stream](https://www.twitch.tv/videos/608372277) . For tips on making Playdate games, [click here](https://sdk.play.date/designing-for-playdate).

Searching in the [Get Help](https://devforum.play.date/c/get-help/38) and [Development Discussion](https://devforum.play.date/c/development-discussion/80) on our Developer Forum to find solutions will also be a good place to look at. If you still need help, the best way to get help from either the community or Panic is to post in that same Get Help category.

### 9.3. Where do I report bugs or issues relating to the SDK?

Head to the [Bug Reports](https://devforum.play.date/c/bugs/47) category and check the [Bug Report category info](https://devforum.play.date/t/about-the-bug-reports-category/1463) for information on how to post a bug report. One of us at Panic will take a look at it!
And what if I have feature requests?

To share your ideas, suggestions, and requests relating to Playdate, head to the [Feature Request](https://devforum.play.date/c/feature-requests/48) category and check the [Feature Request category info](https://devforum.play.date/t/about-the-feature-requests-category/1464) before posting your feature request.

### 9.4. List of Helpful Libraries and Code

This thread includes some helpful tips from the community. Check it out [here](https://devforum.play.date/t/a-list-of-helpful-libraries-and-code/221). For more resources, head to the [Development Discussion](https://devforum.play.date/c/development-discussion/80) category.

## 10. Legal information

Playdate fonts are licensed to you under the [Creative Commons Attribution 4.0 International (CC BY 4.0) license.](https://creativecommons.org/licenses/by/4.0/)
