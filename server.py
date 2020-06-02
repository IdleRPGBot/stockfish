import asyncio

from asyncio.subprocess import PIPE

async def handler(reader, writer):
    process = await asyncio.create_subprocess_shell("./stockfish", stdin=PIPE, stdout=PIPE, stderr=PIPE)

    tasks = {
        asyncio.Task(process.stdout.readline()): (process.stdout, writer),
        asyncio.Task(reader.readline()): (reader, process.stdin),
    }

    while process.returncode is None or not process.stdout.at_eof():
        done, _ = await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)
        fut = done.pop()
        source, target = tasks.pop(fut)
        res = fut.result()
        target.write(res)
        await target.drain()
        tasks[asyncio.Task(source.readline())] = (source, target)

    writer.close()


async def server():
    server = await asyncio.start_server(handler, '0.0.0.0', 4000)
    async with server:
        await server.serve_forever()

asyncio.run(server())
