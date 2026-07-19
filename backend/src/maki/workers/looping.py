import asyncio
import signal


def install_stop_event() -> asyncio.Event:
    event = asyncio.Event()
    loop = asyncio.get_running_loop()
    for signal_name in (signal.SIGINT, signal.SIGTERM):
        try:
            loop.add_signal_handler(signal_name, event.set)
        except NotImplementedError:
            continue
    return event


async def wait_or_stop(event: asyncio.Event, seconds: float) -> None:
    try:
        await asyncio.wait_for(event.wait(), timeout=seconds)
    except TimeoutError:
        return
