examples_src = Path.expand("../priv/examples", __DIR__)

examples_dir =
  Path.join(
    System.tmp_dir!(),
    "blendend_playground_phx_examples_#{System.unique_integer([:positive])}"
  )

File.mkdir_p!(examples_dir)

examples_src
|> File.ls!()
|> Enum.each(fn name ->
  File.cp!(Path.join(examples_src, name), Path.join(examples_dir, name))
end)

Application.put_env(:blendend_playground_phx, :examples_dir, examples_dir)

ExUnit.start()
