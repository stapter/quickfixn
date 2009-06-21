﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace QuickFIX.NET
{
    class StringField : FieldBase<string>
    {
        public StringField(int field, string str)
            : base(field, str) { }

        // quickfix compat
        public string getValue()
        { return Obj; }

        public void setValue(string val)
        { Obj = val; }
    }
}
