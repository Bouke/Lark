import logging
logging.basicConfig(level=logging.DEBUG)

from spyne import Application, rpc, ServiceBase, \
    Integer, Unicode, Enum

from spyne import Iterable

from spyne.protocol.soap import Soap11

from spyne.server.wsgi import WsgiApplication

part_of_day = Enum("morning", "afternoon", "evening", "night", type_name="PartOfDay")

class HelloWorldService(ServiceBase):
    @rpc(Unicode, Integer, _returns=Iterable(Unicode, min_occurs=1))
    def say_hello(ctx, name, times):
        for i in range(times):
            yield 'Hello, %s' % name

    @rpc()
    def say_nothing(ctx):
        return

    @rpc(part_of_day, _returns=Unicode)
    def greet(ctx, part_of_day):
        return 'Good %s' % part_of_day

    @rpc(Iterable(part_of_day, min_occurs=1), _returns=Iterable(Unicode, min_occurs=1))
    def greets(ctx, part_of_days):
        for part_of_day in part_of_days:
            yield 'Good %s' % part_of_day

    @rpc(Unicode, _returns=Unicode(min_occurs=0))
    def say_maybe_nothing(ctx, name):
        return

    @rpc(Unicode, _returns=Unicode(min_occurs=0))
    def say_maybe_something(ctx, name):
        return 'Hello, %s' % name

application = Application([HelloWorldService],
    name='HelloWorld',
    tns='spyne.examples.hello',
    in_protocol=Soap11(validator='lxml'),
    out_protocol=Soap11()
)

if __name__ == '__main__':
    # You can use any Wsgi server. Here, we chose
    # Python's built-in wsgi server but you're not
    # supposed to use it in production.
    from wsgiref.simple_server import make_server

    wsgi_app = WsgiApplication(application)
    server = make_server('0.0.0.0', 8000, wsgi_app)
    server.serve_forever()
