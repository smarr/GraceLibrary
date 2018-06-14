import sys

grace_file_str = ""

class Generator:

    def __init__(self):
        pass

    def make_type(self, name, signatures):
        body = ""
        for s in signatures: body += "    %s\n" % s
        return "type %s = interface {\n%s}\n\n" % (name, body)

    def make_class(self, name, defs, values):
        body = ""
        for (d, v) in zip(defs, values): body += "    def %s = %s\n" % (d, v)
        return "class %s {\n%s}\n\n" % (name, body)

    def invoke_method_with_value(self, signature, value):
        return "%s%s(%s)\n" % (" " * 4, signature, value)

    def method_with_one_typed_parameter(self, signature, argument, type, body):
        return "method %s (%s: %s) {\n%s}\n\n" % (signature, argument, type, body)

    def generate_method_stack(self):
        stack_str = ""

        # Generate type and class
        type_statement = self.make_type("Foo", ["x", "y"])
        stack_str += type_statement

        class_dec = self.make_class("Foo", ["x", "y"], [40, 2])
        stack_str += class_dec
        

        # Generate first method
        method = self.method_with_one_typed_parameter("foo0", "x", "Foo", "    return x\n")
        stack_str += method

        # Generate stack of calls
        names = ["foo%d" % i for i in range(int(sys.argv[2]))]
        for (callee, caller) in zip(names[:-1], names[1:]):
            body = self.invoke_method_with_value(callee, "x")
            method = self.method_with_one_typed_parameter(caller, "x", "Foo", body)
            stack_str += method

        # Invoke bottom method
        stack_str += "%s(%s)\n" % (names[-1], "Foo")

        return stack_str

if __name__ == "__main__":
    file_content = Generator().generate_method_stack()
    with open(sys.argv[1], "w") as f:
        f.write(file_content)
        f.close()