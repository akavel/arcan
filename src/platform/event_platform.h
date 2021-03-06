#ifndef HAVE_EVENT_PLATFORM
#define HAVE_EVENT_PLATFORM

/*
 * get a NULL terminated list of input- platform specific environment options
 * will only be presented to the user in a CLI like setting.
 */
const char** platform_event_envopts();

/*
 * Some platforms have a costly and intrusive detection process for new devices
 * and in such cases, this should be invoked explicitly in safe situations when
 * the render-loop is permitted to stall.
 */
void platform_event_rescan_idev(struct arcan_evctx* ctx);

/*
 * Legacy for translated devices, features like this should most of the time be
 * implemented at a higher layer, state tracking + clock is sufficient to do so
 * The default state for any input platform should be no-repeat.
 * period = 0, disable
 * period | delay < 0, query only
 * returns old value in argument
 */
void platform_event_keyrepeat(struct arcan_evctx*, int* period, int* delay);

/*
 * run once before any other setup in order to provide for platforms that need
 * to do one-time things like opening privileged resources and then dropping
 * them. Unlike video_init, this will only be called once and before
 * environmental variables etc. are applied, so other platform features might
 * be missing.
 *
 * platform_video_preinit will be called prior to this, so it is the job of
 * event_ preinit to actually drop privileges.
 */
void platform_event_preinit();

/*
 * Hook where the platform and event queue is in a ready state, and it is
 * possible to load/lock/discover devices and attach to the event queues of
 * [ctx].
 */
void platform_event_init(struct arcan_evctx* ctx);

/*
 * Last hook before the contents of [ctx] is to be considered useless, remove
 * dangling references, release device locks held and so on. Will be called
 * both on shutdown and when handing over devices/leasing devices to another
 * process.
 */
void platform_event_deinit(struct arcan_evctx* ctx);

/*
 * Some kind of string representation for the device, it may well  be used for
 * identification and tracking purposes so it is desired that this is device
 * specific rather than port specific.
 */
const char* platform_event_devlabel(int devid);

/*
 * Quick-helper to toggle all analog device samples on / off. If mouse is set
 * the action will also be toggled on mouse x / y. This will keep track of the
 * old state, but repeating the same toggle will flush state memory. All
 * devices (except mouse) start in off mode. Devices that are connected after
 * this has been set should use it as a global state identifier (so that we
 * don't saturate or break when a noisy device is plugged in).
 */
void platform_event_analogall(bool enable, bool mouse);

/*
 * Used for recovery handover where a full deinit would be damaging or has
 * some connection to the video layer. One example is for egl-dri related
 * pseudo-terminal management where some IOCTLs affect graphics state.
 */
void platform_event_reset();

/*
 * Special controls for devices that sample relative values but report
 * absolute values based on an internal tracking value and we might need to
 * 'warp' for device control.
 */
void platform_event_samplebase(int devid, float xyz[3]);

/*
 * poll / flush all incoming platform input event into specified context.
 */
void platform_event_process(struct arcan_evctx* ctx);

/*
 * Return a list of possible input device types
 */
enum PLATFORM_EVENT_CAPABILITIES platform_event_capabilities(const char** dst);

/*
 * Update/get the active filter setting for the specific devid / axis (-1 for
 * all) lower_bound / upper_bound sets the [lower < n < upper] where only n
 * values are passed into the filter core (and later on, possibly as events)
 *
 * Buffer_sz is treated as a hint of how many samples in should be considered
 * before emitting a sample out.
 *
 * The implementation is left to the respective platform/input code to handle.
 */
void platform_event_analogfilter(int devid,
	int axisid, int lower_bound, int upper_bound, int deadzone,
	int buffer_sz, enum ARCAN_ANALOGFILTER_KIND kind);

arcan_errc platform_event_analogstate(int devid, int axisid,
	int* lower_bound, int* upper_bound, int* deadzone,
	int* kernel_size, enum ARCAN_ANALOGFILTER_KIND* mode);


#endif
