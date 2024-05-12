import React, { useState, useEffect, Fragment } from "react";
import {
  Button,
  Message,
  Divider,
  Breadcrumb,
  Form,
  Table,
  Header,
  Label,
  Checkbox,
} from "semantic-ui-react";
import { tableSortReducer } from "../Shared/TableSort";

import "semantic-ui-css/semantic.min.css";
import "../Styles/default";

import Breadcrumbs from "../Shared/Breadcrumb";
import MessageBox from "../Shared/MessageBox";
import axios from "axios";
import { Controller, useForm } from "react-hook-form";
import { DateInput } from "semantic-ui-calendar-react";
import RenderValue from "../Shared/RenderValue";

const InvoiceForm = ({
  invoice,
  packing_slips,
  projects,
  selected_ps_ids,
  token,
}) => {
  const [message, setMessage] = useState(null);
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [selPackingSlips, setSelPackingSlips] = useState(selected_ps_ids);
  const [project, setProject] = useState(
    invoice.project ? invoice.project : "SL"
  );

  const {
    handleSubmit,
    reset,
    setValue,
    control,
    formState: { errors },
  } = useForm({
    defaultValues: {
      project: invoice.project ? invoice.project : "SL",
      number: invoice.number,
      invoice_date: invoice.invoice_date
        ? moment(invoice.invoice_date).format("MM/DD/YYYY")
        : null,
    },
  });

  const [state, dispatch] = React.useReducer(tableSortReducer, {
    column: null,
    data: packing_slips.filter((record) => record.project === project),
    direction: null,
  });
  const { column, data: sorted_packing_slips, direction } = state;

  useEffect(() => {
    // filter out by project
    dispatch({
      data: packing_slips.filter((record) => record.project === project),
      type: "UPDATE_DATA",
      column,
      direction,
    });
  }, [project]);

  console.error("invoiceForm", {
    invoice,
    packing_slips,
    projects,
    project,
    selected_ps_ids,
  });

  const resetForm = () => {
    reset({
      project: "",
      number: "",
      invoice_date: "",
    });
    setSelPackingSlips([]);
  };

  const handleChange = (e, { name, value }) => {
    if (name === "project") {
      setProject(value);
    }
    setValue(name, value);
  };

  const onSubmit = (data) => {
    console.log({ data });

    // check that there are selected packing slips
    if (selPackingSlips.length === 0) {
      setMessage({
        status: "Error",
        text: "You must select a Packing Slip to Associate to the Invoice",
      });
    } else {
      // Add the packing slips to the data obj
      data.packing_slips = selPackingSlips;
      data.invoice_date = moment(data.invoice_date, "l").format("YYYY-MM-DD");

      setLoading(true);
      setSubmitted(true);

      if (invoice.id) {
        updateInvoice(data);
      } else {
        createInvoice(data);
      }
    }
  };

  const createInvoice = (data) => {
    axios
      .post(`/invoices`, {
        invoice: data,
        authenticity_token: token,
      })
      .then(({ data }) => {
        console.log("submit response", data);
        // Set message
        setMessage({
          status: data.state ? "Success" : "Error",
          text: data.message,
        });

        if (data.state && data.invoice_id) {
          setTimeout(() => {
            location.href = `/invoices/${data.invoice_id}`;
          }, 3000);
        } else {
          setLoading(false);
          setSubmitted(false);
        }
      })
      .catch((err) => {
        console.log(err.inner);
      });
  };

  const updateInvoice = (data) => {
    axios
      .patch(`/invoices/${invoice.id}`, {
        invoice: data,
        authenticity_token: token,
      })
      .then(({ data }) => {
        console.log("submit response", data);
        // Set message
        setMessage({
          status: data.state ? "Success" : "Error",
          text: data.message,
        });

        if (data.state) {
          setTimeout(() => {
            location.href = `/invoices/${invoice.id}`;
          }, 3000);
        } else {
          setLoading(false);
          setSubmitted(false);
        }
      })
      .catch((err) => {
        console.log(err.inner);
      });
  };

  const deleteRecord = () => {
    setLoading(true);
    setSubmitted(true);
    axios
      .post(`/invoices/${invoice.id}/destroy`, {
        // invoice: { id: invoice.id },
        authenticity_token: token,
      })
      .then(({ data }) => {
        console.log("delete response", data);
        // Set message
        setMessage({
          status: data.state ? "Success" : "Error",
          text: data.message,
        });

        if (data.state) {
          setTimeout(() => {
            location.href = `/invoices/`;
          }, 3000);
        } else {
          setLoading(false);
          setSubmitted(false);
        }
      })
      .catch((err) => {
        console.log(err.inner);
      });
  };

  const checkboxChange = (e, { value, checked }) => {
    console.log("checkboxChange", { value, checked });
    if (selPackingSlips.includes(value)) {
      setSelPackingSlips([...selPackingSlips].filter((ps) => ps != value));
    } else {
      var arr = [...selPackingSlips];
      arr.push(value);
      setSelPackingSlips(arr);
    }
  };

  const checkAll = (e, { checked }) => {
    setSelPackingSlips(checked ? packing_slips.map((ps) => ps.id) : []);
  };

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section href="/invoices">Invoices</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>
          {invoice.id ? `Edit ${invoice.number}` : "Create New Invoice"}
        </Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      {message && <MessageBox status={message.status} message={message.text} />}
      <Form>
        <Form.Group widths="equal">
          <Controller
            name={"project"}
            control={control}
            rules={{ required: "Required" }}
            defaultValue={project}
            render={({ field: { name, value } }) => (
              <Form.Select
                fluid
                search
                selection
                clearable
                name={name}
                label={"Project"}
                required={true}
                value={value}
                onChange={handleChange}
                autoComplete="off"
                options={projects.map((record) => {
                  return {
                    key: record,
                    text: record,
                    value: record,
                  };
                })}
                error={
                  errors["project"]
                    ? {
                        content: errors["project"].message,
                        pointing: "above",
                      }
                    : false
                }
              />
            )}
          />
          <Controller
            name={"number"}
            control={control}
            rules={{ required: "Required" }}
            render={({ field: { name, onChange, value } }) => (
              <Form.Input
                fluid
                autoComplete="off"
                label={"Invoice Number"}
                name={name}
                onChange={onChange}
                value={value || ""}
                error={errors[name] && errors[name].message}
              />
            )}
          />
          <Form.Field error={errors.hasOwnProperty("invoice_date")}>
            <div className="calendar-input">
              <Controller
                name={"invoice_date"}
                control={control}
                rules={{
                  required: "Required",
                }}
                render={({ field: { name, value } }) => (
                  <DateInput
                    closable
                    clearable
                    name={name}
                    label={"Invoice Date"}
                    required={true}
                    value={value || ""}
                    dateFormat="MM/DD/YYYY"
                    iconPosition="left"
                    onChange={handleChange}
                    autoComplete="off"
                  />
                )}
              />
            </div>
            {errors[`invoice_date`] && (
              <Label pointing prompt>
                {errors[`invoice_date`].message}
              </Label>
            )}
          </Form.Field>
        </Form.Group>

        {sorted_packing_slips.length === 0 ? (
          <MessageBox
            status={"Error"}
            message={
              "No Packing Slips that have not been invoiced yet. Packing Slips are created during Final Delivery."
            }
          />
        ) : (
          <>
            <Header as="h4" block inverted>
              Packing Slips available to be invoiced
            </Header>

            <Table unstackable sortable celled striped>
              <Table.Header>
                <Table.Row>
                  <Table.HeaderCell collapsing>
                    <Checkbox
                      onChange={checkAll}
                      checked={
                        packing_slips.length === selPackingSlips.length
                          ? true
                          : false
                      }
                    />
                  </Table.HeaderCell>
                  <Table.HeaderCell
                    sorted={column === "name" ? direction : null}
                    onClick={() =>
                      dispatch({ type: "CHANGE_SORT", column: "name" })
                    }
                  >
                    Name
                  </Table.HeaderCell>
                  <Table.HeaderCell
                    sorted={column === "states" ? direction : null}
                    onClick={() =>
                      dispatch({ type: "CHANGE_SORT", column: "states" })
                    }
                  >
                    State
                  </Table.HeaderCell>
                  <Table.HeaderCell
                    sorted={column === "project" ? direction : null}
                    onClick={() =>
                      dispatch({ type: "CHANGE_SORT", column: "project" })
                    }
                  >
                    Project
                  </Table.HeaderCell>
                  <Table.HeaderCell
                    sorted={column === "tile_count" ? direction : null}
                    onClick={() =>
                      dispatch({ type: "CHANGE_SORT", column: "tile_count" })
                    }
                  >
                    Number of Tiles
                  </Table.HeaderCell>
                  <Table.HeaderCell
                    sorted={column === "shipped_date" ? direction : null}
                    onClick={() =>
                      dispatch({ type: "CHANGE_SORT", column: "shipped_date" })
                    }
                  >
                    Ship Date
                  </Table.HeaderCell>
                </Table.Row>
              </Table.Header>
              <Table.Body>
                {sorted_packing_slips.map((record) => {
                  return (
                    <Table.Row key={record.id}>
                      <Table.HeaderCell
                        collapsing
                        style={{ textAlign: "center" }}
                      >
                        <Checkbox
                          value={record.id}
                          onChange={checkboxChange}
                          checked={
                            selPackingSlips.includes(record.id) ? true : false
                          }
                        />
                      </Table.HeaderCell>
                      <Table.Cell>{record.name}</Table.Cell>
                      <Table.Cell>{record.state_abv}</Table.Cell>
                      <Table.Cell>{record.project}</Table.Cell>
                      <Table.Cell>{record.tile_count}</Table.Cell>
                      <Table.Cell>
                        <RenderValue value={record.shipped_date} date />
                      </Table.Cell>
                    </Table.Row>
                  );
                })}
              </Table.Body>
            </Table>

            <Divider />

            <Button
              primary
              floated="right"
              loading={submitted}
              disabled={submitted || selPackingSlips.length === 0}
              onClick={handleSubmit(onSubmit)}
            >
              Submit
            </Button>
            <Button
              secondary
              floated="right"
              type="button"
              style={{ marginRight: "0.5em" }}
              onClick={() => resetForm()}
            >
              Reset
            </Button>
            {invoice.id && (
              <Button
                negative
                floated="left"
                type="button"
                style={{ marginRight: "0.5em" }}
                onClick={() => deleteRecord()}
              >
                Destroy
              </Button>
            )}
            <div style={{ clear: "both" }} />
          </>
        )}
      </Form>
    </div>
  );
};

export default InvoiceForm;
