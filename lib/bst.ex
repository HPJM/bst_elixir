defmodule BST do
  @moduledoc """
  Handles operations for working with binary search trees.
  """

  @modes ~w(in_order pre_order post_order reverse)a

  alias BST.Node

  @doc """
  Creates new node

  ## Examples
      iex> BST.new(2)
      %BST.Node{data: 2}

  """
  def new(data, left \\ nil, right \\ nil) do
    Node.new(data, left, right)
  end

  @doc """
  Inserts a node into the tree.

  ## Examples

      iex> root = BST.new(2)
      iex> BST.insert(root, 3)
      %BST.Node{data: 2, right: %BST.Node{data: 3}}

  """

  # At leaf - return new node
  def insert(nil, data) do
    new(data)
  end

  # Lower value than current node - recurse down left subtree
  def insert(%Node{left: left, right: right, data: data}, value)
      when value < data do
    new(data, insert(left, value), right)
  end

  # Greater value than current node - recurse down right subtree
  def insert(%Node{left: left, right: right, data: data}, value)
      when value > data do
    new(data, left, insert(right, value))
  end

  # Equal - just return node
  def insert(%Node{left: left, right: right, data: data}, _value) do
    new(data, left, right)
  end

  @doc """
  Inserts multiple nodes into the tree.

  ## Examples

      iex> root = BST.new(2)
      iex> tree = BST.insert_many(root, [5, 50])
      iex> tree.right.right.data
      50

  """
  def insert_many(%Node{} = root, nodes) when is_list(nodes) do
    Enum.reduce(nodes, root, &insert(&2, &1))
  end

  @doc """
  Verifies the tree is valid.

  ## Examples

      iex> BST.new(2) |> BST.insert(3) |> BST.verify?()
      true

  """

  def verify?(%Node{} = node) do
    do_verify?(node, nil, nil)
  end

  # At leaf: this branch must be valid
  defp do_verify?(nil, _min, _max) do
    true
  end

  # Node violates min / max limits
  defp do_verify?(%Node{data: data}, _min, max) when is_number(max) and data > max do
    false
  end

  defp do_verify?(%Node{data: data}, min, _max) when is_number(min) and data < min do
    false
  end

  # Verify left and right subtrees, recursively
  defp do_verify?(%Node{left: left, right: right, data: data}, min, max) do
    do_verify?(left, min, data) and do_verify?(right, data, max)
  end

  @doc """
  Traverses tree, in one of four different modes.
  """
  def traverse(node, callback, mode \\ :in_order)

  def traverse(nil, _callback, _mode) do
    nil
  end

  def traverse(%Node{left: left, right: right} = node, callback, :in_order)
      when is_function(callback, 1) do
    traverse(left, callback, :in_order)
    callback.(node.data)
    traverse(right, callback, :in_order)
  end

  def traverse(%Node{left: left, right: right} = node, callback, :pre_order)
      when is_function(callback, 1) do
    callback.(node.data)
    traverse(left, callback, :pre_order)
    traverse(right, callback, :pre_order)
  end

  def traverse(%Node{left: left, right: right} = node, callback, :post_order)
      when is_function(callback, 1) do
    traverse(left, callback, :post_order)
    traverse(right, callback, :post_order)
    callback.(node.data)
  end

  def traverse(%Node{left: left, right: right} = node, callback, :reverse)
      when is_function(callback, 1) do
    traverse(right, callback, :reverse)
    callback.(node.data)
    traverse(left, callback, :reverse)
  end

  @doc """
  Collects node values from tree into a list, given a traversal mode.

  ## Examples
      iex> tree = BST.new(2) |> BST.insert_many([20, 200])
      iex> tree |> BST.collect()
      [2, 20, 200]
      iex> tree |> BST.collect(:reverse)
      [200, 20, 2]
  """
  def collect(%Node{} = node, mode \\ :in_order) when mode in @modes do
    {:ok, pid} = Agent.start(fn -> [] end)

    traverse(node, &do_collect(pid, &1), mode)

    Agent.get(pid, & &1) |> Enum.reverse()
  end

  defp do_collect(pid, value) when is_pid(pid) do
    Agent.update(pid, &[value | &1])
  end

  @doc """
  Searches tree for node with given value.

  ## Examples
      iex> BST.new(2) |> BST.insert(3) |> BST.search(3)
      %BST.Node{data: 3}

      iex> BST.new(1) |> BST.insert(5) |> BST.search(30)
      nil
  """

  def search(nil, _value) do
    nil
  end

  def search(%Node{data: data} = node, value) when data == value do
    node
  end

  def search(%Node{data: data, left: left}, value) when value < data do
    search(left, value)
  end

  def search(%Node{data: data, right: right}, value) when value > data do
    search(right, value)
  end

  @doc """
  Retrieves smallest node in tree.

  ## Examples
      iex> tree = BST.new(200) |> BST.insert(2) |> BST.insert(33) |> BST.insert(3) |> BST.find_min()
      iex> tree.data
      2
  """
  def find_min(%Node{left: nil} = node) do
    node
  end

  def find_min(%Node{left: left}) do
    find_min(left)
  end

  @doc """
  Removes node from tree.

  ## Examples
      iex> tree = BST.new(3) |> BST.insert(2) |> BST.insert(1) |> BST.delete(2)
      iex> tree.left.data
      1
  """
  def delete(nil, _value) do
    nil
  end

  # Node has no children
  def delete(%Node{data: data, left: nil, right: nil}, value)
      when data == value do
    nil
  end

  # Node has one child
  def delete(%Node{data: data, left: %Node{} = left, right: nil}, value)
      when data == value do
    left
  end

  def delete(%Node{data: data, left: nil, right: %Node{} = right}, value)
      when data == value do
    right
  end

  # Node has two children
  def delete(%Node{data: data, left: %Node{} = left, right: %Node{} = right}, value)
      when data == value do
    # Get left-most child of right
    successor = find_min(right)
    # Move successor up to this node, and replace right branch without it
    right_without_successor = delete(right, successor.data)
    new(successor.data, left, right_without_successor)
  end

  # Recurse down left or right subtrees
  def delete(%Node{data: data, left: left, right: right}, value)
      when value < data do
    new(data, delete(left, value), right)
  end

  def delete(%Node{data: data, left: left, right: right}, value)
      when value > data do
    new(data, left, delete(right, value))
  end

  @doc """
  Removes multiple nodes from tree.

  ## Examples

      iex> tree = BST.new(2) |> BST.insert_many([5, 50])
      iex> BST.delete_many(tree, [5, 50])
      %BST.Node{data: 2, left: nil, right: nil}

  """
  def delete_many(%Node{} = root, nodes) when is_list(nodes) do
    Enum.reduce(nodes, root, &delete(&2, &1))
  end
end
