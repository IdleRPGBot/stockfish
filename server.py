import asyncio

from asyncio.subprocess import PIPE

async def handler(reader, writer):
    process = await asyncio.create_subprocess_shell("./stockfish", stdin=PIPE, stdout=PIPE, stderr=PIPE)

    tasks = {
        asyncio.Task(process.stdout.readline()): 1,
        asyncio.Task(reader.readline()): 2,
    }

    while process.returncode is None or not process.stdout.at_eof():
        done, _ = await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)
        for fut in done:
            val = tasks.pop(fut)
            res = fut.result()
            if val == 1:
                writer.write(res)
                await writer.drain()
                tasks[asyncio.Task(process.stdout.readline())] = 1
            else:
                process.stdin.write(res)
                await process.stdin.drain()
                tasks[asyncio.Task(reader.readline())] = 2
    writer.close()


async def server():
    server = await asyncio.start_server(handler, '0.0.0.0', 4000)
    async with server:
        await server.serve_forever()

asyncio.run(server())
