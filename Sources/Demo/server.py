import logging
logging.basicConfig(level=logging.DEBUG)

from spyne import Application, rpc, ServiceBase, \
    Integer, Unicode, Enum, Fault

from spyne import Iterable

from spyne.protocol.soap import Soap11

from spyne.server.wsgi import WsgiApplication

part_of_day = Enum("morning", "afternoon", "evening", "night", type_name="PartOfDay")

class HelloWorldService(ServiceBase):
    @rpc(Unicode, Integer, _returns=Iterable(Unicode, min_occurs=1))
    def say_hello(self, name, times):
        for i in range(times):
            yield 'Hello, %s' % name

    @rpc()
    def say_nothing(self):
        return

    @rpc(part_of_day, _returns=Unicode)
    def greet(self, part_of_day):
        return 'Good %s' % part_of_day

    @rpc(Iterable(part_of_day, min_occurs=1), _returns=Iterable(Unicode, min_occurs=1))
    def greets(self, part_of_days):
        for part_of_day in part_of_days:
            yield 'Good %s' % part_of_day

    @rpc(Unicode, _returns=Unicode(min_occurs=0))
    def say_maybe_nothing(self, name):
        return

    @rpc(Unicode, _returns=Unicode(min_occurs=0))
    def say_maybe_something(self, name):
        return 'Hello, %s' % name

    @rpc()
    def fault(self):
        raise Fault(faultstring="a fault, as promised")


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
